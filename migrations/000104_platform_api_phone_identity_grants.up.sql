-- Exact phone-identity capabilities for the authenticated platform enrollment
-- contract. platform_api_svc is established by 000101 and receives mathprep
-- schema USAGE from 000102; the identity table is created by 000100.
GRANT SELECT (phone_identity_id, principal_id, phone_e164, status)
    ON mathprep.phone_identity TO platform_api_svc;

GRANT INSERT (phone_identity_id, principal_id, phone_e164, status)
    ON mathprep.phone_identity TO platform_api_svc;

GRANT UPDATE (status, verified_at, revoked_at)
    ON mathprep.phone_identity TO platform_api_svc;

