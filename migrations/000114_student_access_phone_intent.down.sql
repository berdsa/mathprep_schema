DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_student_access_intent LIMIT 1) THEN
        RAISE EXCEPTION 'refusing to roll back 000114: student access intent rows exist';
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION mathprep.prune_platform_student_access_intents(integer)
    FROM platform_api_svc;
REVOKE ALL ON FUNCTION mathprep.prune_platform_student_access_intents(integer)
    FROM PUBLIC;
DROP FUNCTION mathprep.prune_platform_student_access_intents(integer);
REVOKE SELECT, DELETE ON mathprep.platform_student_access_intent
    FROM platform_auth_retention_svc;
REVOKE UPDATE (email) ON mathprep.platform_accounts FROM platform_api_svc;
REVOKE UPDATE (status, finalized_at, email, password_hash, phone_e164, device_binding)
    ON mathprep.platform_student_access_intent FROM platform_api_svc;
REVOKE INSERT (
    intent_id, tenant_id, child_id, child_principal_id,
    guardian_relationship_id, guardian_principal_id,
    email, password_hash, phone_e164, device_binding, expires_at
) ON mathprep.platform_student_access_intent FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_student_access_intent FROM platform_api_svc;
DROP TRIGGER platform_student_access_lifecycle_guard
    ON mathprep.platform_student_access_intent;
DROP FUNCTION mathprep.guard_student_access_intent_transition();
DROP TRIGGER platform_student_access_scope_guard
    ON mathprep.platform_student_access_intent;
DROP FUNCTION mathprep.assert_student_access_intent_scope();
DROP TABLE mathprep.platform_student_access_intent;
