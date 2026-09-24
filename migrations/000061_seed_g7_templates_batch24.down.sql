DELETE FROM task_type_template
WHERE type_id IN ('G7-ALG-026', 'G7-FUN-013', 'G7-STA-010', 'G7-STA-011', 'G7-GEO-012', 'G7-GEO-003', 'G7-GEO-006', 'G7-GEO-007', 'G7-GEO-008', 'G7-GEO-009')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
