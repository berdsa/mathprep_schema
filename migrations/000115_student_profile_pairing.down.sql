DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_student_profile_link LIMIT 1) THEN
        RAISE EXCEPTION 'refusing to roll back 000115: student profile link history exists';
    END IF;
END;
$$;

REVOKE UPDATE (family_tenant_id,child_id,pairing_code_digest,status,family_confirmed_at,student_confirmed_at,closed_at)
    ON mathprep.platform_student_profile_link FROM platform_api_svc;
REVOKE INSERT (link_id,student_principal_id,student_tenant_id,pairing_code_digest,status,expires_at)
    ON mathprep.platform_student_profile_link FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_student_profile_link FROM platform_api_svc;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='mathprep_platform_local') THEN
        REVOKE UPDATE (family_tenant_id,child_id,pairing_code_digest,status,family_confirmed_at,student_confirmed_at,closed_at)
            ON mathprep.platform_student_profile_link FROM mathprep_platform_local;
        REVOKE INSERT (link_id,student_principal_id,student_tenant_id,pairing_code_digest,status,expires_at)
            ON mathprep.platform_student_profile_link FROM mathprep_platform_local;
        REVOKE SELECT ON mathprep.platform_student_profile_link FROM mathprep_platform_local;
    END IF;
END;
$$;
DROP TRIGGER platform_student_profile_link_lifecycle_guard ON mathprep.platform_student_profile_link;
DROP FUNCTION mathprep.guard_student_profile_link_transition();
DROP TRIGGER platform_student_profile_link_scope_guard ON mathprep.platform_student_profile_link;
DROP FUNCTION mathprep.assert_student_profile_link_scope();
DROP TABLE mathprep.platform_student_profile_link;
