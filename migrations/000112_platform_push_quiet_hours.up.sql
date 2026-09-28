-- Account-level quiet hours for generic Web Push. A row is optional: no row
-- (or a NULL quiet window) preserves immediate delivery behavior.
CREATE TABLE mathprep.platform_push_preferences (
    principal_id UUID PRIMARY KEY REFERENCES mathprep.access_principals(id) ON DELETE CASCADE,
    quiet_start TIME,
    quiet_end TIME,
    time_zone TEXT NOT NULL DEFAULT 'Asia/Almaty',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    CONSTRAINT platform_push_preferences_quiet_pair CHECK (
        (quiet_start IS NULL AND quiet_end IS NULL)
        OR (quiet_start IS NOT NULL AND quiet_end IS NOT NULL AND quiet_start <> quiet_end)
    )
);

REVOKE ALL PRIVILEGES ON mathprep.platform_push_preferences
    FROM PUBLIC, platform_api_svc, mathprep_notifications_svc;
GRANT SELECT, INSERT, DELETE ON mathprep.platform_push_preferences TO mathprep_notifications_svc;
GRANT UPDATE (quiet_start, quiet_end, time_zone, updated_at)
    ON mathprep.platform_push_preferences TO mathprep_notifications_svc;
