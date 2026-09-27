-- Preserve intent/device history. Rollback is permitted only while all three
-- tables are empty; callers must export or explicitly resolve retained rows.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_registration_intent LIMIT 1)
       OR EXISTS (SELECT 1 FROM mathprep.platform_login_intent LIMIT 1)
       OR EXISTS (SELECT 1 FROM mathprep.platform_trusted_device LIMIT 1) THEN
        RAISE EXCEPTION 'refusing to roll back 000107: pre-auth intent/device rows exist';
    END IF;
END;
$$;

REVOKE UPDATE (last_seen_at, expires_at, revoked_at)
    ON mathprep.platform_trusted_device FROM platform_api_svc;
REVOKE INSERT (verified_at)
    ON mathprep.phone_identity FROM platform_api_svc;
REVOKE INSERT (trusted_device_id, principal_id, token_digest, expires_at)
    ON mathprep.platform_trusted_device FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_trusted_device FROM platform_api_svc;

REVOKE UPDATE (device_token_digest, status)
    ON mathprep.platform_login_intent FROM platform_api_svc;
REVOKE INSERT (
    intent_id, principal_id, membership_id, phone_identity_id,
    device_binding, device_token_digest, expires_at
) ON mathprep.platform_login_intent FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_login_intent FROM platform_api_svc;

REVOKE UPDATE (status, finalized_principal_id, finalized_at)
    ON mathprep.platform_registration_intent FROM platform_api_svc;
REVOKE INSERT (
    intent_id, email, password_hash, display_name, locale, requested_role,
    phone_e164, terms_version, device_binding, expires_at
) ON mathprep.platform_registration_intent FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_registration_intent FROM platform_api_svc;

DROP TABLE mathprep.platform_trusted_device;
DROP TABLE mathprep.platform_login_intent;
DROP TABLE mathprep.platform_registration_intent;
