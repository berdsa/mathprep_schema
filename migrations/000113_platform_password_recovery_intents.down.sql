DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_password_recovery_intent LIMIT 1) THEN
        RAISE EXCEPTION 'refusing to roll back 000113: password recovery intent rows exist';
    END IF;
END;
$$;

-- Restore the bounded cleanup function body from migration 000109.
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
    RETURN removed;
END;
$$;

ALTER FUNCTION mathprep.prune_platform_preauth_state(integer)
    OWNER TO platform_auth_retention_svc;
REVOKE ALL ON FUNCTION mathprep.prune_platform_preauth_state(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mathprep.prune_platform_preauth_state(integer)
    TO platform_api_svc;

REVOKE SELECT, DELETE ON mathprep.platform_password_recovery_intent
    FROM platform_auth_retention_svc;
REVOKE UPDATE (password_hash) ON mathprep.platform_accounts FROM platform_api_svc;
REVOKE UPDATE (status, completed_at)
    ON mathprep.platform_password_recovery_intent FROM platform_api_svc;
REVOKE INSERT (
    intent_id, principal_id, phone_identity_id, device_binding, expires_at
) ON mathprep.platform_password_recovery_intent FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_password_recovery_intent FROM platform_api_svc;
DROP TABLE mathprep.platform_password_recovery_intent;
