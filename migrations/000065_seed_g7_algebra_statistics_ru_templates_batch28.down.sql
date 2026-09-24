DELETE FROM task_type_template
WHERE type_id IN ('G7-ALG-001', 'G7-ALG-002', 'G7-ALG-004', 'G7-ALG-005', 'G7-FRA-005', 'G7-STA-008', 'G7-STA-009')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
