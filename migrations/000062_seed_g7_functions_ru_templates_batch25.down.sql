DELETE FROM task_type_template
WHERE type_id IN ('G7-FUN-002', 'G7-FUN-003', 'G7-FUN-004', 'G7-FUN-005', 'G7-FUN-006', 'G7-FUN-007', 'G7-FUN-008', 'G7-FUN-009', 'G7-FUN-010', 'G7-FUN-011', 'G7-FUN-012')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
