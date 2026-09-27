-- Durable handoff from the platform inbox writer to the independent push
-- notification service. The inbox row and this row are inserted together.
CREATE TABLE mathprep.platform_push_outbox (
    notification_id UUID PRIMARY KEY
        REFERENCES mathprep.platform_notifications(id) ON DELETE RESTRICT,
    recipient_principal_id UUID NOT NULL,
    event_kind TEXT NOT NULL
        CHECK (event_kind IN ('join_requested', 'join_approved', 'join_declined')),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'in_progress', 'delivered', 'dead')),
    attempt_count SMALLINT NOT NULL DEFAULT 0
        CHECK (attempt_count BETWEEN 0 AND 10),
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    lease_token UUID,
    lease_expires_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    last_error_class TEXT
        CHECK (last_error_class IS NULL OR last_error_class IN (
            'transient', 'permanent', 'subscription_gone', 'provider_unavailable', 'internal'
        )),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    CONSTRAINT platform_push_outbox_lifecycle_check CHECK (
        (status = 'pending' AND lease_token IS NULL AND lease_expires_at IS NULL
            AND delivered_at IS NULL)
        OR (status = 'in_progress' AND lease_token IS NOT NULL
            AND lease_expires_at IS NOT NULL AND delivered_at IS NULL)
        OR (status = 'delivered' AND lease_token IS NULL
            AND lease_expires_at IS NULL AND delivered_at IS NOT NULL)
        OR (status = 'dead' AND lease_token IS NULL
            AND lease_expires_at IS NULL AND delivered_at IS NULL)
    )
);

CREATE INDEX platform_push_outbox_pending_claim_idx
    ON mathprep.platform_push_outbox (next_attempt_at, created_at)
    WHERE status = 'pending';

CREATE INDEX platform_push_outbox_expired_lease_idx
    ON mathprep.platform_push_outbox (lease_expires_at, created_at)
    WHERE status = 'in_progress';

-- The platform API writes one reference row in the same transaction as the
-- inbox notification. The notification service may inspect and advance queue
-- state, but cannot enqueue, delete, or rewrite recipient/event identity.
REVOKE ALL PRIVILEGES ON mathprep.platform_push_outbox
    FROM PUBLIC, platform_api_svc, mathprep_notifications_svc;
GRANT USAGE ON SCHEMA mathprep TO platform_api_svc;
GRANT INSERT (notification_id, recipient_principal_id, event_kind)
    ON mathprep.platform_push_outbox TO platform_api_svc;
GRANT SELECT ON mathprep.platform_push_outbox TO mathprep_notifications_svc;
GRANT UPDATE (
    status,
    attempt_count,
    next_attempt_at,
    lease_token,
    lease_expires_at,
    delivered_at,
    last_error_class,
    updated_at
) ON mathprep.platform_push_outbox TO mathprep_notifications_svc;
