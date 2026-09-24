DELETE FROM task_type_template
WHERE type_id IN (
    'G7-FRA-001', 'G7-FRA-002', 'G7-FRA-003', 'G7-FRA-004',
    'G7-DEC-001', 'G7-DEC-002', 'G7-DEC-003', 'G7-DEC-004',
    'G7-GEO-001', 'G7-GEO-002', 'G7-GEO-004', 'G7-GEO-005'
)
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
