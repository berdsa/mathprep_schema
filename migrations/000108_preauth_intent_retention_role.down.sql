DROP INDEX mathprep.platform_trusted_device_retention_idx;
DROP INDEX mathprep.platform_login_intent_retention_idx;
DROP INDEX mathprep.platform_registration_intent_retention_idx;
REVOKE platform_auth_retention_svc FROM platform_api_svc;
REVOKE DELETE ON mathprep.platform_registration_intent,
    mathprep.platform_login_intent,
    mathprep.platform_trusted_device
    FROM platform_auth_retention_svc;
REVOKE USAGE ON SCHEMA mathprep FROM platform_auth_retention_svc;
DROP ROLE platform_auth_retention_svc;
