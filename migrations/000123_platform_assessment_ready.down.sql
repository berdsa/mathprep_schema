DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM mathprep.platform_notifications
        WHERE kind='assessment_ready' OR session_id IS NOT NULL
    ) OR EXISTS (
        SELECT 1 FROM mathprep.platform_push_outbox
        WHERE event_kind='assessment_ready'
    ) THEN
        RAISE EXCEPTION 'cannot roll back assessment_ready while assessment inbox or outbox rows exist; archive/remove them deliberately first';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='mathprep' AND table_name='platform_notifications'
          AND column_name='reference_id' AND is_nullable<>'YES'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_notifications'::regclass
          AND c.conname='platform_notifications_kind_check'
          AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%assessment_ready%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_push_outbox'::regclass
          AND c.conname='platform_push_outbox_event_kind_check'
          AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%assessment_ready%'
    ) THEN
        RAISE EXCEPTION 'cannot restore 000123 baseline: expected assessment_ready constraints or nullable reference_id are missing';
    END IF;
END $$;

REVOKE INSERT (session_id)
    ON mathprep.platform_notifications FROM platform_api_svc;

ALTER TABLE mathprep.platform_push_outbox
    DROP CONSTRAINT platform_push_outbox_event_kind_check,
    ADD CONSTRAINT platform_push_outbox_event_kind_check CHECK (
        event_kind IN ('join_requested','join_approved','join_declined')
    );

ALTER TABLE mathprep.platform_notifications
    DROP CONSTRAINT platform_notifications_kind_check,
    ADD CONSTRAINT platform_notifications_kind_check CHECK (
        kind IN ('join_requested','join_approved','join_declined')
    );

DROP INDEX mathprep.platform_notifications_assessment_ready_session_uq;

ALTER TABLE mathprep.platform_notifications
    DROP CONSTRAINT platform_notifications_event_reference_check,
    DROP CONSTRAINT platform_notifications_session_id_fkey,
    DROP COLUMN session_id,
    ALTER COLUMN reference_id SET NOT NULL;
