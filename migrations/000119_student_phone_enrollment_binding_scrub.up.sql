-- Completed/expired enrollment intents deliberately erase their device binding.
-- 000118's initial NOT NULL declaration contradicted its terminal-state check.
ALTER TABLE mathprep.platform_student_phone_enrollment_intent
    ALTER COLUMN device_binding DROP NOT NULL;
