INSERT INTO domain (code) VALUES
    ('NUM'), ('FRA'), ('DEC'), ('GEO'), ('MEA'), ('ALG'), ('FUN'), ('STA'),
    ('PRO'), ('TRG'), ('LOG'), ('VEC'), ('MAT'), ('CAL'), ('DIS');

INSERT INTO grade_band (code) VALUES
    ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'), ('10'),
    ('11'), ('UNIVERSITY');

INSERT INTO tier_code (code) VALUES
    ('T1'), ('T2'), ('T3');

INSERT INTO validation_method (code) VALUES
    ('EXACT-INT'), ('EXACT-RAT'), ('TOL'), ('SET'), ('CANON'), ('CAS'),
    ('BOOL'), ('TUPLE'), ('MATRIX');

INSERT INTO equivalence_policy (code) VALUES
    ('STRICT-FORM'), ('EQUIV-CLASS'), ('CAS-EQUIV');

INSERT INTO generation_mode (code) VALUES
    ('CODE'), ('HYBRID-AI');

INSERT INTO task_type_status (code) VALUES
    ('DRAFT'), ('GATED'), ('FINAL');

INSERT INTO verdict (code) VALUES
    ('CORRECT'), ('INCORRECT'), ('UNPARSEABLE');

INSERT INTO reason_code (code) VALUES
    ('OK'), ('PARSE_ERROR'), ('EMPTY_INPUT'), ('INPUT_TOO_LONG'),
    ('WRONG_FORMAT'), ('VALUE_MISMATCH'), ('CANON_NOT_REDUCED'),
    ('INCOMPLETE_TUPLE'), ('SET_CARDINALITY_MISMATCH'), ('CAS_TIMEOUT');

INSERT INTO render_target (code) VALUES
    ('plaintext'), ('unicode-math');

INSERT INTO locale (code) VALUES
    ('ru-KZ');

INSERT INTO user_type (code) VALUES
    ('STUDENT'), ('GUARDIAN'), ('ADMIN');
