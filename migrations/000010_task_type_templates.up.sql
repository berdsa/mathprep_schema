CREATE TABLE task_type_template (
    type_id TEXT NOT NULL REFERENCES task_type(type_id) ON DELETE CASCADE,
    locale TEXT NOT NULL REFERENCES locale(code),
    template_text TEXT NOT NULL CHECK (octet_length(template_text) BETWEEN 1 AND 8192),
    spec_version TEXT NOT NULL,
    PRIMARY KEY (type_id, locale, spec_version)
);

CREATE INDEX task_type_template_lookup_idx
    ON task_type_template (type_id, locale);

INSERT INTO task_type_template (type_id, locale, template_text, spec_version)
VALUES
    ('G3-NUM-002', 'ru-KZ', '{{a}} × {{b}} = ?', '1.0.0-draft'),
    ('G3-NUM-003', 'ru-KZ', '{{a}} ÷ {{b}} = ?', '1.0.0-draft'),
    ('G3-FRA-008', 'ru-KZ', 'What is 1/{{b}} of {{n}}?', '1.0.0-draft'),
    ('G6-NUM-002', 'ru-KZ', '{{a}} {{operator}} {{b}} = ?', '1.0.0-draft'),
    ('G5-FRA-003', 'ru-KZ', '{{a}}/{{b}} + {{c}}/{{d}} = ?', '1.0.0-draft');
