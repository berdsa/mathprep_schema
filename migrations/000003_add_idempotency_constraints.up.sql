ALTER TABLE generation_request
    ADD CONSTRAINT generation_request_student_idempotency_key_key
    UNIQUE (student_id, idempotency_key);

ALTER TABLE task_set
    ADD CONSTRAINT task_set_student_idempotency_key_key
    UNIQUE (student_id, idempotency_key);

ALTER TABLE submission
    ADD CONSTRAINT submission_item_student_idempotency_key_key
    UNIQUE (item_id, student_id, idempotency_key);
