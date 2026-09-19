ALTER TABLE submission
    DROP CONSTRAINT submission_item_student_idempotency_key_key;

ALTER TABLE task_set
    DROP CONSTRAINT task_set_student_idempotency_key_key;

ALTER TABLE generation_request
    DROP CONSTRAINT generation_request_student_idempotency_key_key;
