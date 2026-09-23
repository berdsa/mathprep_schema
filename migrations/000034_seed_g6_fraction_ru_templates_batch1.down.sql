DELETE FROM task_type_template
WHERE type_id IN ('G6-FRA-001', 'G6-FRA-002', 'G6-FRA-003', 'G6-FRA-004', 'G6-FRA-005', 'G6-FRA-006', 'G6-FRA-007', 'G6-FRA-008', 'G6-FRA-009', 'G6-FRA-010')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
