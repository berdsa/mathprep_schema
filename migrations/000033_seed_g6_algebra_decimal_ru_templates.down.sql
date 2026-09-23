DELETE FROM task_type_template
WHERE type_id IN ('G6-ALG-008', 'G6-ALG-009', 'G6-ALG-010', 'G6-DEC-001', 'G6-DEC-002', 'G6-DEC-003', 'G6-DEC-004', 'G6-DEC-005', 'G6-DEC-006', 'G6-DEC-007')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
