CREATE TABLE domain (
    code TEXT PRIMARY KEY
);

CREATE TABLE grade_band (
    code TEXT PRIMARY KEY
);

CREATE TABLE tier_code (
    code TEXT PRIMARY KEY
);

CREATE TABLE validation_method (
    code TEXT PRIMARY KEY
);

CREATE TABLE equivalence_policy (
    code TEXT PRIMARY KEY
);

CREATE TABLE generation_mode (
    code TEXT PRIMARY KEY
);

CREATE TABLE task_type_status (
    code TEXT PRIMARY KEY
);

CREATE TABLE verdict (
    code TEXT PRIMARY KEY
);

CREATE TABLE reason_code (
    code TEXT PRIMARY KEY
);

CREATE TABLE render_target (
    code TEXT PRIMARY KEY
);

CREATE TABLE locale (
    code TEXT PRIMARY KEY
);

CREATE TABLE user_type (
    code TEXT PRIMARY KEY
);

CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    user_type TEXT NOT NULL REFERENCES user_type(code)
);

CREATE TABLE students (
    user_id UUID PRIMARY KEY REFERENCES users(user_id),
    grade INTEGER NOT NULL
);

CREATE TABLE generation_request (
    request_id UUID PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES students(user_id),
    grade INTEGER NOT NULL,
    topics JSONB NOT NULL,
    count INTEGER NOT NULL CHECK (count > 0),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'IN_PROGRESS', 'DONE', 'FAILED')),
    idempotency_key TEXT NOT NULL,
    lease_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE task_type (
    type_id TEXT PRIMARY KEY,
    domain TEXT NOT NULL REFERENCES domain(code),
    grade INTEGER NOT NULL,
    spec_version TEXT NOT NULL,
    generation_mode TEXT NOT NULL REFERENCES generation_mode(code),
    status TEXT NOT NULL REFERENCES task_type_status(code),
    equivalence_policy TEXT NOT NULL REFERENCES equivalence_policy(code),
    validation_method TEXT NOT NULL REFERENCES validation_method(code),
    locale TEXT NOT NULL REFERENCES locale(code)
);

CREATE TABLE task_set (
    task_set_id UUID PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES students(user_id),
    request_id UUID NOT NULL REFERENCES generation_request(request_id),
    issued_at TIMESTAMPTZ NOT NULL,
    idempotency_key TEXT NOT NULL
);

CREATE TABLE task_instance (
    item_id UUID PRIMARY KEY,
    type_id TEXT NOT NULL REFERENCES task_type(type_id),
    spec_version TEXT NOT NULL,
    tier TEXT NOT NULL REFERENCES tier_code(code),
    locale TEXT NOT NULL REFERENCES locale(code),
    render_target TEXT NOT NULL REFERENCES render_target(code),
    seed BIGINT NOT NULL,
    params_json JSONB NOT NULL,
    problem_text TEXT NOT NULL,
    correct_answer_json JSONB NOT NULL,
    task_set_id UUID NOT NULL REFERENCES task_set(task_set_id)
);

CREATE TABLE submission (
    submission_id UUID PRIMARY KEY,
    item_id UUID NOT NULL REFERENCES task_instance(item_id),
    student_id UUID NOT NULL REFERENCES students(user_id),
    raw_input TEXT NOT NULL,
    verdict TEXT NOT NULL REFERENCES verdict(code),
    reason_code TEXT NOT NULL REFERENCES reason_code(code),
    attempt_index INTEGER NOT NULL CHECK (attempt_index >= 0),
    submitted_at TIMESTAMPTZ NOT NULL,
    idempotency_key TEXT NOT NULL
);

CREATE TABLE mastery_topic (
    student_id UUID NOT NULL REFERENCES students(user_id),
    domain TEXT NOT NULL REFERENCES domain(code),
    tier TEXT NOT NULL REFERENCES tier_code(code),
    ema_score DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (student_id, domain, tier)
);

CREATE TABLE event_log (
    event_id UUID PRIMARY KEY,
    event_type TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    payload_json JSONB NOT NULL
);
