-- Remove only the phone_identity column privileges added by 000104.
REVOKE SELECT (phone_identity_id, principal_id, phone_e164, status)
    ON mathprep.phone_identity FROM platform_api_svc;

REVOKE INSERT (phone_identity_id, principal_id, phone_e164, status)
    ON mathprep.phone_identity FROM platform_api_svc;

REVOKE UPDATE (status, verified_at, revoked_at)
    ON mathprep.phone_identity FROM platform_api_svc;

