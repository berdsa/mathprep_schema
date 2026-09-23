CREATE TABLE answer_widget (
    code TEXT PRIMARY KEY
);

INSERT INTO answer_widget (code) VALUES
    ('NUMERIC'),
    ('FRACTION'),
    ('CHOICE'),
    ('TUPLE_N'),
    ('SET_LIST'),
    ('MATRIX_GRID'),
    ('STRUCTURED_CANON'),
    ('EXPRESSION');
