-- CAS is a separate, least-privileged PostgreSQL job-queue consumer.  The
-- bounds below are deliberately enforced at the persistence boundary: no
-- unbounded hostile expression or policy payload can reach the worker.

CREATE TABLE cas_operation_type (
    code TEXT PRIMARY KEY
);

CREATE TABLE cas_evaluation_status (
    code TEXT PRIMARY KEY
);

CREATE TABLE event_type (
    code TEXT PRIMARY KEY
);

INSERT INTO cas_operation_type (code) VALUES
    ('EQUIVALENCE');

INSERT INTO cas_evaluation_status (code) VALUES
    ('PENDING'), ('IN_PROGRESS'), ('DONE'), ('FAILED');

INSERT INTO event_type (code) VALUES
    ('GENERATION_REQUESTED'),
    ('GENERATION_COMPLETED'),
    ('GENERATION_FAILED'),
    ('SUBMISSION_GRADED'),
    ('MASTERY_UPDATED'),
    ('CAS_EVALUATION_COMPLETED'),
    ('CAS_EVALUATION_FAILED');

ALTER TABLE event_log
    ADD CONSTRAINT event_log_event_type_fkey
    FOREIGN KEY (event_type) REFERENCES event_type(code);

CREATE TABLE cas_evaluation_request (
    request_id UUID PRIMARY KEY,
    requester_id UUID NOT NULL REFERENCES users(user_id),
    session_id TEXT NOT NULL
        CHECK (octet_length(session_id) BETWEEN 1 AND 128),
    operation_type TEXT NOT NULL
        REFERENCES cas_operation_type(code),
    candidate_expression TEXT NOT NULL
        CHECK (octet_length(candidate_expression) BETWEEN 1 AND 8192),
    reference_expression TEXT NOT NULL
        CHECK (octet_length(reference_expression) BETWEEN 1 AND 8192),
    policy_json JSONB NOT NULL
        CHECK (
            octet_length(policy_json::TEXT) <= 16384
            AND jsonb_typeof(policy_json) = 'object'
            AND policy_json ? 'allowed_symbols'
            AND jsonb_typeof(policy_json->'allowed_symbols') = 'array'
            AND policy_json ? 'allowed_functions'
            AND jsonb_typeof(policy_json->'allowed_functions') = 'array'
            AND policy_json ? 'limits'
            AND jsonb_typeof(policy_json->'limits') = 'object'
        ),
    status TEXT NOT NULL REFERENCES cas_evaluation_status(code),
    verdict TEXT REFERENCES verdict(code),
    reason_code TEXT REFERENCES reason_code(code),
    result_json JSONB
        CHECK (
            result_json IS NULL
            OR (
                octet_length(result_json::TEXT) <= 65536
                AND jsonb_typeof(result_json) = 'object'
            )
        ),
    created_at TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    lease_expires_at TIMESTAMPTZ,
    heartbeat_at TIMESTAMPTZ,
    wall_deadline_at TIMESTAMPTZ NOT NULL
        CHECK (wall_deadline_at > created_at),
    attempt_count INTEGER NOT NULL DEFAULT 0
        CHECK (attempt_count BETWEEN 0 AND 10),
    CONSTRAINT cas_evaluation_request_lifecycle_check CHECK (
        (status = 'PENDING'
            AND started_at IS NULL
            AND completed_at IS NULL
            AND lease_expires_at IS NULL
            AND heartbeat_at IS NULL
            AND verdict IS NULL
            AND reason_code IS NULL
            AND result_json IS NULL)
        OR
        (status = 'IN_PROGRESS'
            AND started_at IS NOT NULL
            AND completed_at IS NULL
            AND lease_expires_at IS NOT NULL
            AND heartbeat_at IS NOT NULL
            AND verdict IS NULL
            AND reason_code IS NULL
            AND result_json IS NULL)
        OR
        (status IN ('DONE', 'FAILED')
            AND started_at IS NOT NULL
            AND completed_at IS NOT NULL
            AND verdict IS NOT NULL
            AND reason_code IS NOT NULL)
    ),
    CONSTRAINT cas_evaluation_request_timeout_verdict_check CHECK (
        reason_code IS DISTINCT FROM 'CAS_TIMEOUT'
        OR verdict = 'UNPARSEABLE'
    )
);

CREATE INDEX cas_evaluation_request_claim_idx
    ON cas_evaluation_request (status, lease_expires_at, created_at);

CREATE INDEX cas_evaluation_request_session_created_at_idx
    ON cas_evaluation_request (session_id, created_at);

CREATE ROLE cas_svc
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT;

REVOKE ALL ON cas_evaluation_request, event_log,
    cas_operation_type, cas_evaluation_status, verdict, reason_code, event_type
    FROM cas_svc;

GRANT USAGE ON SCHEMA public TO cas_svc;

GRANT SELECT, INSERT ON cas_evaluation_request TO cas_svc;
GRANT UPDATE (
    status,
    verdict,
    reason_code,
    result_json,
    started_at,
    completed_at,
    lease_expires_at,
    heartbeat_at,
    attempt_count
) ON cas_evaluation_request TO cas_svc;
GRANT INSERT ON event_log TO cas_svc;
GRANT SELECT ON cas_operation_type, cas_evaluation_status, verdict, reason_code
    TO cas_svc;
