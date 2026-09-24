DELETE FROM task_type_template
WHERE (type_id, locale, render_target, spec_version) IN (
    ('G4-MEA-006', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-007', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-008', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-009', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-010', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-011', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-012', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-STA-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-013', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-014', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-015', 'ru-KZ', 'plaintext', '1.0.0-draft')
);
