-- One-use, short-lived state for a guardian to provision sign-in credentials
-- and a student-owned phone on an already-existing child principal. OTP
-- challenge state stays in Auth/Redis. This row is not an account, consent, or
-- verified phone identity.
CREATE TABLE mathprep.platform_student_access_intent (
    intent_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT,
    child_id UUID NOT NULL REFERENCES mathprep.platform_children(id) ON DELETE RESTRICT,
    child_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    guardian_relationship_id UUID NOT NULL REFERENCES mathprep.access_guardian_relationships(id) ON DELETE RESTRICT,
    guardian_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    email TEXT CHECK (email IS NULL OR (email = lower(email) AND length(email) BETWEEN 3 AND 320 AND position('@' IN email) > 1)),
    password_hash TEXT CHECK (password_hash IS NULL OR length(password_hash) BETWEEN 1 AND 1024),
    phone_e164 TEXT CHECK (phone_e164 IS NULL OR phone_e164 ~ '^\+[1-9][0-9]{1,14}$'),
    device_binding TEXT CHECK (device_binding IS NULL OR device_binding ~ '^[a-f0-9]{64}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'finalized', 'expired')),
    finalized_at TIMESTAMPTZ,
    CHECK (expires_at > created_at AND expires_at <= created_at + interval '15 minutes'),
    CHECK ((status = 'pending' AND finalized_at IS NULL AND email IS NOT NULL AND password_hash IS NOT NULL AND phone_e164 IS NOT NULL AND device_binding IS NOT NULL)
        OR (status IN ('finalized', 'expired') AND finalized_at IS NOT NULL AND email IS NULL AND password_hash IS NULL AND phone_e164 IS NULL AND device_binding IS NULL)),
    CHECK (finalized_at IS NULL OR finalized_at >= created_at),
    CHECK ((status = 'finalized' AND finalized_at <= expires_at)
        OR status = 'pending'
        OR (status = 'expired' AND finalized_at >= expires_at))
);

CREATE UNIQUE INDEX platform_student_access_one_pending_child_idx
    ON mathprep.platform_student_access_intent(child_id) WHERE status = 'pending';
CREATE INDEX platform_student_access_pending_expiry_idx
    ON mathprep.platform_student_access_intent(expires_at) WHERE status = 'pending';
CREATE INDEX platform_student_access_retention_idx
    ON mathprep.platform_student_access_intent(expires_at, finalized_at);

-- A row can only bind the child principal and guardian relationship that
-- already exist together in the same family tenant. Consent remains a separate
-- authorization check by Platform API and is neither created nor inferred here.
CREATE FUNCTION mathprep.assert_student_access_intent_scope()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, mathprep
AS $$
DECLARE
    child_tenant UUID;
    child_principal UUID;
    child_learner UUID;
    relationship_tenant UUID;
    relationship_guardian UUID;
    relationship_learner UUID;
    tenant_kind TEXT;
BEGIN
    SELECT tenant_id, principal_id, learner_id
      INTO child_tenant, child_principal, child_learner
      FROM mathprep.platform_children WHERE id = NEW.child_id;
    SELECT tenant_id, guardian_principal_id, learner_id
      INTO relationship_tenant, relationship_guardian, relationship_learner
      FROM mathprep.access_guardian_relationships WHERE id = NEW.guardian_relationship_id;
    SELECT kind INTO tenant_kind FROM mathprep.access_tenants WHERE id = NEW.tenant_id;
    IF tenant_kind IS DISTINCT FROM 'family'
       OR child_tenant IS DISTINCT FROM NEW.tenant_id
       OR child_principal IS DISTINCT FROM NEW.child_principal_id
       OR relationship_tenant IS DISTINCT FROM NEW.tenant_id
       OR relationship_guardian IS DISTINCT FROM NEW.guardian_principal_id
       OR relationship_learner IS DISTINCT FROM child_learner THEN
        RAISE EXCEPTION 'student access intent child and guardian scope do not match';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION mathprep.assert_student_access_intent_scope() FROM PUBLIC;
CREATE TRIGGER platform_student_access_scope_guard
    BEFORE INSERT ON mathprep.platform_student_access_intent
    FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_access_intent_scope();

CREATE FUNCTION mathprep.guard_student_access_intent_transition()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, mathprep
AS $$
BEGIN
    IF OLD.status <> 'pending'
       OR NEW.status NOT IN ('finalized', 'expired')
       OR NEW.finalized_at IS NULL
       OR NEW.tenant_id IS DISTINCT FROM OLD.tenant_id
       OR NEW.child_id IS DISTINCT FROM OLD.child_id
       OR NEW.child_principal_id IS DISTINCT FROM OLD.child_principal_id
       OR NEW.guardian_relationship_id IS DISTINCT FROM OLD.guardian_relationship_id
       OR NEW.guardian_principal_id IS DISTINCT FROM OLD.guardian_principal_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
       OR NEW.email IS NOT NULL OR NEW.password_hash IS NOT NULL
       OR NEW.phone_e164 IS NOT NULL OR NEW.device_binding IS NOT NULL THEN
        RAISE EXCEPTION 'student access intent permits only one-use finalization or expiry with secret scrubbing';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION mathprep.guard_student_access_intent_transition() FROM PUBLIC;
CREATE TRIGGER platform_student_access_lifecycle_guard
    BEFORE UPDATE ON mathprep.platform_student_access_intent
    FOR EACH ROW EXECUTE FUNCTION mathprep.guard_student_access_intent_transition();

REVOKE ALL PRIVILEGES ON mathprep.platform_student_access_intent
    FROM PUBLIC, platform_api_svc, platform_auth_retention_svc;
GRANT SELECT ON mathprep.platform_student_access_intent TO platform_api_svc;
GRANT INSERT (
    intent_id, tenant_id, child_id, child_principal_id,
    guardian_relationship_id, guardian_principal_id,
    email, password_hash, phone_e164, device_binding, expires_at
) ON mathprep.platform_student_access_intent TO platform_api_svc;
GRANT UPDATE (status, finalized_at, email, password_hash, phone_e164, device_binding)
    ON mathprep.platform_student_access_intent TO platform_api_svc;

-- Finalization uses the existing child principal; it may replace its email
-- only after the Auth OTP gate, in the same transaction as verified phone
-- insertion and intent scrubbing. The service must re-check guardian scope,
-- consent, account/email uniqueness, OTP intent, and device digest.
GRANT UPDATE (email) ON mathprep.platform_accounts TO platform_api_svc;

GRANT SELECT, DELETE ON mathprep.platform_student_access_intent
    TO platform_auth_retention_svc;
CREATE FUNCTION mathprep.prune_platform_student_access_intents(batch_size integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, mathprep
AS $$
DECLARE
    removed integer := 0;
BEGIN
    IF batch_size < 1 OR batch_size > 500 THEN
        RAISE EXCEPTION 'batch_size must be between 1 and 500';
    END IF;
    DELETE FROM mathprep.platform_student_access_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_student_access_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;
ALTER FUNCTION mathprep.prune_platform_student_access_intents(integer)
    OWNER TO platform_auth_retention_svc;
REVOKE ALL ON FUNCTION mathprep.prune_platform_student_access_intents(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mathprep.prune_platform_student_access_intents(integer)
    TO platform_api_svc;
