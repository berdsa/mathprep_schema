-- A recipient-specific locale lookup filters on principal_id and returns only
-- locale. Keep both grants column-scoped; do not expose account profile data.
GRANT SELECT (principal_id, locale)
    ON mathprep.platform_accounts TO mathprep_notifications_svc;
