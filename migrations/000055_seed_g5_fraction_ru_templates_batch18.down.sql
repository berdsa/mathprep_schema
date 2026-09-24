DELETE FROM task_type_template
WHERE (type_id, locale, render_target, spec_version) IN (
    ('G5-FRA-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-002', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-004', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-005', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-006', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-007', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-008', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-009', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-FRA-010', 'ru-KZ', 'plaintext', '1.0.0-draft')
);
UPDATE task_type_template
SET template_text = '{{a}}/{{b}} + {{c}}/{{d}} = ?'
WHERE type_id = 'G5-FRA-003' AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
