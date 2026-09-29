-- Extend the recovered, already-deployed platform inbox contract for the
-- assessment-ready event. This is deliberately not base-table/bootstrap DDL.
-- Abort if the live baseline differs from the reviewed platform contract.
DO $$
DECLARE
    notification_columns TEXT[] := ARRAY[
        'id', 'tenant_id', 'recipient_principal_id', 'kind', 'reference_id',
        'class_id', 'created_at', 'read_at'
    ];
    session_columns TEXT[] := ARRAY[
        'id', 'child_id', 'mode', 'status', 'test_id', 'finished_at'
    ];
    outbox_columns TEXT[] := ARRAY[
        'notification_id', 'recipient_principal_id', 'event_kind', 'status',
        'attempt_count', 'next_attempt_at', 'lease_token', 'lease_expires_at',
        'delivered_at', 'last_error_class', 'created_at', 'updated_at'
    ];
BEGIN
    IF to_regclass('mathprep.platform_notifications') IS NULL
       OR to_regclass('mathprep.platform_learning_sessions') IS NULL
       OR to_regclass('mathprep.platform_push_outbox') IS NULL THEN
        RAISE EXCEPTION '000123 requires recovered platform notification, learning-session, and push-outbox baseline tables';
    END IF;

    IF EXISTS (
        SELECT 1 FROM unnest(notification_columns) AS required(column_name)
        WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_schema='mathprep' AND c.table_name='platform_notifications'
              AND c.column_name=required.column_name
        )
    ) OR EXISTS (
        SELECT 1 FROM unnest(session_columns) AS required(column_name)
        WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_schema='mathprep' AND c.table_name='platform_learning_sessions'
              AND c.column_name=required.column_name
        )
    ) OR EXISTS (
        SELECT 1 FROM unnest(outbox_columns) AS required(column_name)
        WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_schema='mathprep' AND c.table_name='platform_push_outbox'
              AND c.column_name=required.column_name
        )
    ) THEN
        RAISE EXCEPTION '000123 baseline platform table columns are incomplete';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_notifications'::regclass
          AND c.conname='platform_notifications_kind_check'
          AND c.contype='c'
          AND pg_get_constraintdef(c.oid) LIKE '%join_requested%'
          AND pg_get_constraintdef(c.oid) LIKE '%join_approved%'
          AND pg_get_constraintdef(c.oid) LIKE '%join_declined%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_notifications'::regclass
          AND c.conname='platform_notifications_reference_id_fkey'
          AND c.contype='f' AND c.confrelid='mathprep.platform_join_requests'::regclass
          AND pg_get_constraintdef(c.oid) LIKE 'FOREIGN KEY (reference_id) REFERENCES mathprep.platform_join_requests(id)%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_notifications'::regclass
          AND c.conname='platform_notifications_class_id_fkey'
          AND c.contype='f' AND c.confrelid='mathprep.platform_classes'::regclass
          AND pg_get_constraintdef(c.oid) LIKE 'FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id)%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_notifications'::regclass
          AND c.conname='platform_notifications_pkey'
          AND c.contype='p'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_notifications'::regclass
          AND c.conname='platform_notifications_recipient_principal_id_tenant_id_kin_key'
          AND c.contype='u'
          AND pg_get_constraintdef(c.oid) LIKE 'UNIQUE (recipient_principal_id, tenant_id, kind, reference_id)'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_learning_sessions'::regclass
          AND c.conname='platform_learning_sessions_test_id_fkey'
          AND c.contype='f' AND c.confrelid='mathprep.platform_tests'::regclass
          AND pg_get_constraintdef(c.oid) LIKE 'FOREIGN KEY (test_id) REFERENCES mathprep.platform_tests(id)%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_learning_sessions'::regclass
          AND c.conname='platform_learning_sessions_pkey'
          AND c.contype='p'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_learning_sessions'::regclass
          AND c.conname='platform_learning_sessions_status_check'
          AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%finished%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_push_outbox'::regclass
          AND c.conname='platform_push_outbox_event_kind_check'
          AND c.contype='c'
          AND pg_get_constraintdef(c.oid) LIKE '%join_requested%'
          AND pg_get_constraintdef(c.oid) LIKE '%join_approved%'
          AND pg_get_constraintdef(c.oid) LIKE '%join_declined%'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_push_outbox'::regclass
          AND c.conname='platform_push_outbox_pkey'
          AND c.contype='p'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        WHERE c.conrelid='mathprep.platform_push_outbox'::regclass
          AND c.conname='platform_push_outbox_notification_identity_fkey'
          AND c.contype='f' AND c.confrelid='mathprep.platform_notifications'::regclass
          AND pg_get_constraintdef(c.oid) LIKE 'FOREIGN KEY (notification_id, recipient_principal_id, event_kind) REFERENCES mathprep.platform_notifications(id, recipient_principal_id, kind)%'
    ) OR to_regclass('mathprep.platform_notifications_push_outbox_identity_uq') IS NULL THEN
        RAISE EXCEPTION '000123 baseline platform table constraints/indexes do not match the reviewed contract';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='mathprep' AND table_name='platform_notifications'
          AND column_name='reference_id' AND is_nullable='NO' AND data_type='uuid'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='mathprep' AND table_name='platform_notifications'
          AND column_name='class_id' AND is_nullable='NO' AND data_type='uuid'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='mathprep' AND table_name='platform_notifications'
          AND column_name='recipient_principal_id' AND is_nullable='NO' AND data_type='uuid'
    ) OR NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='mathprep' AND table_name='platform_notifications'
          AND column_name='tenant_id' AND is_nullable='NO' AND data_type='uuid'
    ) THEN
        RAISE EXCEPTION '000123 expects baseline inbox reference, class, recipient, and tenant UUID columns to be NOT NULL';
    END IF;
END $$;

ALTER TABLE mathprep.platform_notifications
    ADD COLUMN session_id UUID,
    ALTER COLUMN reference_id DROP NOT NULL;

ALTER TABLE mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_session_id_fkey
        FOREIGN KEY (session_id)
        REFERENCES mathprep.platform_learning_sessions(id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT platform_notifications_event_reference_check CHECK (
        (kind='assessment_ready' AND reference_id IS NULL AND session_id IS NOT NULL)
        OR (kind IN ('join_requested','join_approved','join_declined')
            AND reference_id IS NOT NULL AND session_id IS NULL)
    );

CREATE UNIQUE INDEX platform_notifications_assessment_ready_session_uq
    ON mathprep.platform_notifications (recipient_principal_id, tenant_id, session_id)
    WHERE kind='assessment_ready';

ALTER TABLE mathprep.platform_notifications
    DROP CONSTRAINT platform_notifications_kind_check,
    ADD CONSTRAINT platform_notifications_kind_check CHECK (
        kind IN ('join_requested','join_approved','join_declined','assessment_ready')
    );

ALTER TABLE mathprep.platform_push_outbox
    DROP CONSTRAINT platform_push_outbox_event_kind_check,
    ADD CONSTRAINT platform_push_outbox_event_kind_check CHECK (
        event_kind IN ('join_requested','join_approved','join_declined','assessment_ready')
    );

-- Only the platform API producer supplies the typed session reference.
GRANT INSERT (session_id)
    ON mathprep.platform_notifications TO platform_api_svc;
