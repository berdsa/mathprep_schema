DELETE FROM task_type_template
WHERE type_id IN ('G10-ALG-001', 'G10-ALG-003', 'G10-ALG-004', 'G10-ALG-005', 'G10-ALG-007', 'G10-ALG-008', 'G10-ALG-009', 'G10-ALG-010', 'G10-CAL-001', 'G10-FUN-001')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
