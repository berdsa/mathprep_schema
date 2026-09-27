DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_push_outbox) THEN
        RAISE EXCEPTION 'cannot drop mathprep.platform_push_outbox while delivery records exist; drain/archive them deliberately first';
    END IF;
END $$;

REVOKE ALL PRIVILEGES ON mathprep.platform_push_outbox
    FROM platform_api_svc, mathprep_notifications_svc;
DROP INDEX mathprep.platform_push_outbox_expired_lease_idx;
DROP INDEX mathprep.platform_push_outbox_pending_claim_idx;
DROP TABLE mathprep.platform_push_outbox;
DROP INDEX mathprep.platform_notifications_push_outbox_identity_uq;
