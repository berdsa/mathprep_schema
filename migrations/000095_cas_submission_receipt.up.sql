CREATE TABLE cas_submission (
    submission_id UUID PRIMARY KEY
        REFERENCES cas_evaluation_request(request_id),
    item_id UUID NOT NULL REFERENCES task_instance(item_id),
    student_id UUID NOT NULL REFERENCES students(user_id),
    idempotency_key TEXT NOT NULL,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT cas_submission_item_student_idempotency_key_key
        UNIQUE (item_id, student_id, idempotency_key)
);

REVOKE ALL ON cas_evaluation_request, cas_submission, task_set FROM grader_svc;
GRANT SELECT, INSERT ON cas_evaluation_request, cas_submission TO grader_svc;
GRANT SELECT ON task_set TO grader_svc;
