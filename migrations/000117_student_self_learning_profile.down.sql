DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_learning_sessions WHERE self_profile_id IS NOT NULL)
       OR EXISTS (SELECT 1 FROM mathprep.platform_student_self_profile) THEN
        RAISE EXCEPTION 'refusing to roll back 000117: self-owned learning history exists';
    END IF;
END $$;
REVOKE INSERT (id,tenant_id,event_type,actor_principal_id,correlation_id,safe_payload)
    ON mathprep.access_audit_events FROM platform_api_svc;
REVOKE INSERT (self_profile_id) ON mathprep.platform_learning_sessions FROM platform_api_svc;
REVOKE SELECT, INSERT (profile_id,student_principal_id,student_tenant_id,engine_student_id,name,grade,locale,preview_notice_version)
    ON mathprep.platform_student_self_profile FROM platform_api_svc;
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='mathprep_platform_local') THEN
        REVOKE INSERT (id,tenant_id,event_type,actor_principal_id,correlation_id,safe_payload)
            ON mathprep.access_audit_events FROM mathprep_platform_local;
        REVOKE INSERT (self_profile_id) ON mathprep.platform_learning_sessions FROM mathprep_platform_local;
        REVOKE SELECT, INSERT (profile_id,student_principal_id,student_tenant_id,engine_student_id,name,grade,locale,preview_notice_version)
            ON mathprep.platform_student_self_profile FROM mathprep_platform_local;
    END IF;
END $$;
DROP INDEX mathprep.platform_learning_sessions_profile_idx;
DROP INDEX mathprep.platform_learning_sessions_self_idempotency_idx;
ALTER TABLE mathprep.platform_learning_sessions DROP CONSTRAINT platform_learning_sessions_one_owner_check;
ALTER TABLE mathprep.platform_learning_sessions DROP COLUMN self_profile_id;
ALTER TABLE mathprep.platform_learning_sessions ALTER COLUMN child_id SET NOT NULL;
DROP TRIGGER platform_student_self_profile_owner_guard ON mathprep.platform_student_self_profile;
DROP FUNCTION mathprep.assert_student_self_profile_owner();
DROP TABLE mathprep.platform_student_self_profile;
