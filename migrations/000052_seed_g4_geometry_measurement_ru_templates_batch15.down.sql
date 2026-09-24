DELETE FROM task_type_template
WHERE (type_id, locale, render_target, spec_version) IN (
    ('G4-GEO-001', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-GEO-002', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-GEO-003', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-GEO-004', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-GEO-005', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-GEO-007', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-002', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-003', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-004', 'ru-KZ', 'plaintext', '1.0.0-draft'),
    ('G4-MEA-005', 'ru-KZ', 'plaintext', '1.0.0-draft')
);
