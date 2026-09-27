-- Permit the platform API to run bounded pre-auth data cleanup only after
-- explicitly switching to a dedicated role. Ordinary request queries retain
-- their existing no-DELETE permissions.
CREATE ROLE platform_auth_retention_svc NOLOGIN;
GRANT USAGE ON SCHEMA mathprep TO platform_auth_retention_svc;
GRANT DELETE ON mathprep.platform_registration_intent,
    mathprep.platform_login_intent,
    mathprep.platform_trusted_device
    TO platform_auth_retention_svc;

-- Membership is SETtable but not inherited by platform_api_svc. This keeps
-- DELETE unavailable to normal application queries and grants no access to
-- unrelated tables.
GRANT platform_auth_retention_svc TO platform_api_svc
    WITH INHERIT FALSE, SET TRUE;

CREATE INDEX platform_registration_intent_retention_idx
    ON mathprep.platform_registration_intent (expires_at, finalized_at);
CREATE INDEX platform_login_intent_retention_idx
    ON mathprep.platform_login_intent (expires_at);
CREATE INDEX platform_trusted_device_retention_idx
    ON mathprep.platform_trusted_device (expires_at, revoked_at);
