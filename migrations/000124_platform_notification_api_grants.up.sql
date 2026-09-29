-- Least-column grants for the Platform API inbox writer and authenticated
-- notification list/read queries. The local runtime role is provisioned
-- separately and must inherit platform_api_svc; it is not a schema grant.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='platform_api_svc') THEN
        RAISE EXCEPTION '000124 requires the platform_api_svc group role';
    END IF;

    IF to_regclass('mathprep.platform_notifications') IS NULL
       OR to_regclass('mathprep.platform_learning_sessions') IS NULL
       OR to_regclass('mathprep.platform_push_outbox') IS NULL THEN
        RAISE EXCEPTION '000124 requires platform notification, learning-session, and push-outbox relations';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM (VALUES
            ('platform_notifications','id'),
            ('platform_notifications','tenant_id'),
            ('platform_notifications','recipient_principal_id'),
            ('platform_notifications','kind'),
            ('platform_notifications','reference_id'),
            ('platform_notifications','session_id'),
            ('platform_notifications','class_id'),
            ('platform_notifications','created_at'),
            ('platform_notifications','read_at'),
            ('platform_learning_sessions','id'),
            ('platform_learning_sessions','test_id'),
            ('platform_learning_sessions','child_id'),
            ('platform_learning_sessions','mode'),
            ('platform_learning_sessions','status'),
            ('platform_learning_sessions','finished_at'),
            ('platform_tests','id'),('platform_tests','class_id'),
            ('platform_classes','id'),('platform_classes','school_id'),
            ('platform_schools','id'),('platform_schools','tenant_id'),
            ('access_tenants','id'),('access_tenants','status'),
            ('platform_children','id'),('platform_children','tenant_id'),
            ('platform_children','status'),('platform_children','principal_id'),
            ('platform_children','learner_id'),
            ('platform_placements','child_id'),('platform_placements','class_id'),
            ('platform_placements','status'),
            ('access_memberships','tenant_id'),('access_memberships','principal_id'),
            ('access_memberships','status'),('access_memberships','role'),
            ('access_principals','id'),('access_principals','status'),
            ('platform_teacher_classes','class_id'),('platform_teacher_classes','principal_id'),
            ('platform_join_requests','id'),('platform_join_requests','class_id'),
            ('platform_join_requests','child_id'),
            ('access_guardian_relationships','learner_id'),
            ('access_guardian_relationships','tenant_id'),
            ('access_guardian_relationships','guardian_principal_id'),
            ('access_guardian_relationships','state')
        ) AS required(table_name,column_name)
        WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_schema='mathprep'
              AND c.table_name=required.table_name
              AND c.column_name=required.column_name
        )
    ) THEN
        RAISE EXCEPTION '000124 required inbox or recipient-scope columns are missing';
    END IF;

    IF NOT has_column_privilege('platform_api_svc','mathprep.platform_push_outbox','notification_id','INSERT')
       OR NOT has_column_privilege('platform_api_svc','mathprep.platform_push_outbox','recipient_principal_id','INSERT')
       OR NOT has_column_privilege('platform_api_svc','mathprep.platform_push_outbox','event_kind','INSERT') THEN
        RAISE EXCEPTION '000124 requires the existing 000102 outbox identity INSERT grants';
    END IF;
END $$;

GRANT SELECT (
    id, kind, reference_id, session_id, class_id, created_at, read_at,
    recipient_principal_id, tenant_id
) ON mathprep.platform_notifications TO platform_api_svc;
GRANT INSERT (
    id, tenant_id, recipient_principal_id, kind, reference_id, class_id, session_id
) ON mathprep.platform_notifications TO platform_api_svc;
GRANT UPDATE (read_at)
    ON mathprep.platform_notifications TO platform_api_svc;

GRANT SELECT (id, test_id, child_id, mode, status, finished_at)
    ON mathprep.platform_learning_sessions TO platform_api_svc;
GRANT SELECT (id, class_id)
    ON mathprep.platform_tests TO platform_api_svc;
GRANT SELECT (id, school_id)
    ON mathprep.platform_classes TO platform_api_svc;
GRANT SELECT (id, tenant_id)
    ON mathprep.platform_schools TO platform_api_svc;
GRANT SELECT (id, status)
    ON mathprep.access_tenants TO platform_api_svc;
GRANT SELECT (id, tenant_id, status, principal_id, learner_id)
    ON mathprep.platform_children TO platform_api_svc;
GRANT SELECT (child_id, class_id, status)
    ON mathprep.platform_placements TO platform_api_svc;
GRANT SELECT (tenant_id, principal_id, status, role)
    ON mathprep.access_memberships TO platform_api_svc;
GRANT SELECT (id, status)
    ON mathprep.access_principals TO platform_api_svc;
GRANT SELECT (class_id, principal_id)
    ON mathprep.platform_teacher_classes TO platform_api_svc;
GRANT SELECT (id, class_id, child_id)
    ON mathprep.platform_join_requests TO platform_api_svc;
GRANT SELECT (learner_id, tenant_id, guardian_principal_id, state)
    ON mathprep.access_guardian_relationships TO platform_api_svc;

-- Migration 000102 already grants INSERT on exactly the outbox identity
-- columns. This migration intentionally leaves that contract unchanged.
