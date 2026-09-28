-- Durable one-use state for account recovery. The OTP and raw cookie remain
-- in Auth/Redis; this row binds finalization to the current verified phone.
CREATE TABLE mathprep.platform_password_recovery_intent (
    intent_id UUID PRIMARY KEY,
    principal_id UUID NOT NULL
        REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    phone_identity_id UUID NOT NULL
        REFERENCES mathprep.phone_identity(phone_identity_id) ON DELETE RESTRICT,
    device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'completed', 'expired')),
    completed_at TIMESTAMPTZ,
    CHECK (expires_at > created_at),
    CHECK (
        (status IN ('pending', 'expired') AND completed_at IS NULL)
        OR (status = 'completed' AND completed_at IS NOT NULL)
    ),
    CHECK (completed_at IS NULL OR completed_at >= created_at)
);

CREATE UNIQUE INDEX platform_password_recovery_one_pending_principal_idx
    ON mathprep.platform_password_recovery_intent(principal_id)
    WHERE status = 'pending';
CREATE INDEX platform_password_recovery_pending_expiry_idx
    ON mathprep.platform_password_recovery_intent(expires_at)
    WHERE status = 'pending';
CREATE INDEX platform_password_recovery_retention_idx
    ON mathprep.platform_password_recovery_intent(expires_at, completed_at);

REVOKE ALL PRIVILEGES ON mathprep.platform_password_recovery_intent
    FROM PUBLIC, platform_api_svc, platform_auth_retention_svc;
GRANT SELECT ON mathprep.platform_password_recovery_intent TO platform_api_svc;
GRANT INSERT (
    intent_id, principal_id, phone_identity_id, device_binding, expires_at
) ON mathprep.platform_password_recovery_intent TO platform_api_svc;
GRANT UPDATE (status, completed_at)
    ON mathprep.platform_password_recovery_intent TO platform_api_svc;
GRANT UPDATE (password_hash) ON mathprep.platform_accounts TO platform_api_svc;

-- The API can request cleanup but cannot delete directly or inherit the
-- dedicated retention role's access during ordinary requests.
GRANT SELECT, DELETE ON mathprep.platform_password_recovery_intent
    TO platform_auth_retention_svc;

-- Preserve the existing bounded cleanup behavior and include recovery rows.
CREATE OR REPLACE FUNCTION mathprep.prune_platform_preauth_state(batch_size integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, mathprep
AS $$
DECLARE
    removed integer := 0;
    affected integer := 0;
BEGIN
    IF batch_size < 1 OR batch_size > 500 THEN
        RAISE EXCEPTION 'batch_size must be between 1 and 500';
    END IF;

    DELETE FROM mathprep.platform_registration_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_registration_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;

    DELETE FROM mathprep.platform_login_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_login_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;

    DELETE FROM mathprep.platform_trusted_device
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_trusted_device
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
           OR revoked_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;

    DELETE FROM mathprep.platform_password_recovery_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_password_recovery_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;
    RETURN removed;
END;
$$;

ALTER FUNCTION mathprep.prune_platform_preauth_state(integer)
    OWNER TO platform_auth_retention_svc;
REVOKE ALL ON FUNCTION mathprep.prune_platform_preauth_state(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mathprep.prune_platform_preauth_state(integer)
    TO platform_api_svc;
