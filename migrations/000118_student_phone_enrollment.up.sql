-- Password-verified recovery for an existing student principal with no
-- verified phone. OTP and sessions remain in Auth/Redis; this intent stores
-- only identity binding and lifecycle metadata, never a raw phone or OTP.
CREATE TABLE mathprep.platform_student_phone_enrollment_intent (
    intent_id UUID PRIMARY KEY,
    principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    membership_id UUID NOT NULL REFERENCES mathprep.access_memberships(id) ON DELETE RESTRICT,
    device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','completed','expired')),
    completed_at TIMESTAMPTZ,
    CHECK (expires_at > created_at AND expires_at <= created_at + interval '10 minutes'),
    CHECK ((status = 'pending' AND completed_at IS NULL AND device_binding IS NOT NULL)
        OR (status IN ('completed','expired') AND completed_at IS NOT NULL AND device_binding IS NULL)),
    CHECK (completed_at IS NULL OR completed_at >= created_at),
    CHECK ((status = 'completed' AND completed_at <= expires_at)
        OR status = 'pending'
        OR (status = 'expired' AND completed_at >= expires_at))
);

CREATE UNIQUE INDEX platform_student_phone_enrollment_one_pending_principal_idx
    ON mathprep.platform_student_phone_enrollment_intent(principal_id) WHERE status = 'pending';
CREATE INDEX platform_student_phone_enrollment_pending_expiry_idx
    ON mathprep.platform_student_phone_enrollment_intent(expires_at) WHERE status = 'pending';
CREATE INDEX platform_student_phone_enrollment_retention_idx
    ON mathprep.platform_student_phone_enrollment_intent(expires_at, completed_at);

CREATE FUNCTION mathprep.assert_student_phone_enrollment_scope()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, mathprep AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM mathprep.access_principals p
        JOIN mathprep.access_memberships m ON m.principal_id = p.id
        JOIN mathprep.access_tenants t ON t.id = m.tenant_id
        WHERE p.id = NEW.principal_id AND p.status = 'active'
          AND m.id = NEW.membership_id AND m.status = 'active' AND m.role = 'student'
          AND t.status = 'active' AND t.kind = 'student'
    ) THEN
        RAISE EXCEPTION 'phone enrollment requires the exact active student membership';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION mathprep.assert_student_phone_enrollment_scope() FROM PUBLIC;
CREATE TRIGGER platform_student_phone_enrollment_scope_guard
    BEFORE INSERT ON mathprep.platform_student_phone_enrollment_intent
    FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_phone_enrollment_scope();

CREATE FUNCTION mathprep.guard_student_phone_enrollment_transition()
RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog, mathprep AS $$
BEGIN
    IF OLD.status <> 'pending'
       OR NEW.status NOT IN ('completed','expired')
       OR NEW.completed_at IS NULL
       OR NEW.intent_id IS DISTINCT FROM OLD.intent_id
       OR NEW.principal_id IS DISTINCT FROM OLD.principal_id
       OR NEW.membership_id IS DISTINCT FROM OLD.membership_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
       OR NEW.device_binding IS NOT NULL THEN
        RAISE EXCEPTION 'phone enrollment intent permits only one-use completion or expiry with binding scrubbing';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION mathprep.guard_student_phone_enrollment_transition() FROM PUBLIC;
CREATE TRIGGER platform_student_phone_enrollment_lifecycle_guard
    BEFORE UPDATE ON mathprep.platform_student_phone_enrollment_intent
    FOR EACH ROW EXECUTE FUNCTION mathprep.guard_student_phone_enrollment_transition();

REVOKE ALL PRIVILEGES ON mathprep.platform_student_phone_enrollment_intent
    FROM PUBLIC, platform_api_svc, platform_auth_retention_svc;
GRANT SELECT ON mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;
GRANT INSERT (intent_id, principal_id, membership_id, device_binding, expires_at)
    ON mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;
GRANT UPDATE (status, completed_at, device_binding)
    ON mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;
GRANT SELECT, DELETE ON mathprep.platform_student_phone_enrollment_intent
    TO platform_auth_retention_svc;

CREATE FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(batch_size integer)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, mathprep AS $$
DECLARE removed integer := 0;
BEGIN
    IF batch_size < 1 OR batch_size > 500 THEN
        RAISE EXCEPTION 'batch_size must be between 1 and 500';
    END IF;
    DELETE FROM mathprep.platform_student_phone_enrollment_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_student_phone_enrollment_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;
ALTER FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(integer)
    OWNER TO platform_auth_retention_svc;
REVOKE ALL ON FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(integer)
    TO platform_api_svc;
