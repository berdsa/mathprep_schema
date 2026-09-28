DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.platform_student_phone_enrollment_intent) THEN
        RAISE EXCEPTION 'refusing to roll back 000118 while student phone enrollment intent rows exist';
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(integer)
    FROM platform_api_svc;
DROP FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(integer);
REVOKE SELECT, DELETE ON mathprep.platform_student_phone_enrollment_intent
    FROM platform_auth_retention_svc;
REVOKE UPDATE (status, completed_at, device_binding)
    ON mathprep.platform_student_phone_enrollment_intent FROM platform_api_svc;
REVOKE INSERT (intent_id, principal_id, membership_id, device_binding, expires_at)
    ON mathprep.platform_student_phone_enrollment_intent FROM platform_api_svc;
REVOKE SELECT ON mathprep.platform_student_phone_enrollment_intent FROM platform_api_svc;
DROP TRIGGER platform_student_phone_enrollment_lifecycle_guard
    ON mathprep.platform_student_phone_enrollment_intent;
DROP TRIGGER platform_student_phone_enrollment_scope_guard
    ON mathprep.platform_student_phone_enrollment_intent;
DROP FUNCTION mathprep.guard_student_phone_enrollment_transition();
DROP FUNCTION mathprep.assert_student_phone_enrollment_scope();
DROP TABLE mathprep.platform_student_phone_enrollment_intent;
