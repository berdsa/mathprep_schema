DELETE FROM task_type_template
WHERE (type_id, locale, render_target, spec_version) IN (
    ('G4-NUM-005', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-NUM-006', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-002', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-003', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-004', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-005', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-006', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-007', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-FRA-008', 'ru-KZ', 'plaintext', '1.0.0-draft')
);
