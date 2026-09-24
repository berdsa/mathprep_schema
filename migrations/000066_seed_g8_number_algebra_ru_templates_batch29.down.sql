DELETE FROM task_type_template
WHERE type_id IN ('G8-NUM-001', 'G8-NUM-002', 'G8-NUM-003', 'G8-NUM-004', 'G8-NUM-005', 'G8-GEO-003', 'G8-NUM-006', 'G8-NUM-007', 'G8-NUM-008', 'G8-ALG-005')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
