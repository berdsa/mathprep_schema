DELETE FROM task_type_template
WHERE type_id IN ('G7-STA-001', 'G7-STA-002', 'G7-STA-003', 'G7-STA-004', 'G7-STA-005', 'G7-STA-006', 'G7-STA-007', 'G7-GEO-010', 'G7-GEO-023', 'G7-GEO-024')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
