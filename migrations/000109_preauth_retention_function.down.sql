REVOKE EXECUTE ON FUNCTION mathprep.prune_platform_preauth_state(integer)
    FROM platform_api_svc;
DROP FUNCTION mathprep.prune_platform_preauth_state(integer);
REVOKE SELECT ON mathprep.platform_registration_intent,
    mathprep.platform_login_intent,
    mathprep.platform_trusted_device
    FROM platform_auth_retention_svc;
GRANT platform_auth_retention_svc TO platform_api_svc
    WITH INHERIT FALSE, SET TRUE;
