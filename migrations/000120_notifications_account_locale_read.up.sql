-- The notification worker needs only the stored UI locale to render the
-- generic Web Push copy in the recipient's language. Do not grant account
-- table access or expose other profile fields to the delivery service.
GRANT SELECT (locale)
    ON mathprep.platform_accounts TO mathprep_notifications_svc;
