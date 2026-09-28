DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM mathprep.platform_student_phone_enrollment_intent
        WHERE device_binding IS NULL
    ) THEN
        RAISE EXCEPTION 'refusing to restore NOT NULL while terminal student phone enrollment intents remain';
    END IF;
END;
$$;
ALTER TABLE mathprep.platform_student_phone_enrollment_intent
    ALTER COLUMN device_binding SET NOT NULL;
