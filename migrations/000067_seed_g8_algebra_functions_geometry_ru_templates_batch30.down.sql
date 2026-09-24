DELETE FROM task_type_template
WHERE type_id IN ('G8-ALG-006', 'G8-ALG-007', 'G8-ALG-008', 'G8-ALG-009', 'G8-FUN-002', 'G8-FUN-003', 'G8-GEO-004', 'G8-GEO-005', 'G8-GEO-006', 'G8-GEO-007')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
