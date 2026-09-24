DELETE FROM task_type_template
WHERE (type_id, locale, render_target, spec_version) IN (
    ('G5-GEO-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-GEO-002', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-GEO-003', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-002', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-003', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-004', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-005', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-006', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-MEA-007', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-STA-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G5-DIS-001', 'ru-KZ', 'plaintext', '1.0.0-draft')
);
