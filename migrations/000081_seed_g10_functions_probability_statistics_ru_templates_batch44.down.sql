DELETE FROM task_type_template
WHERE type_id IN ('G10-FUN-002', 'G10-FUN-003', 'G10-PRO-001', 'G10-PRO-002', 'G10-PRO-003', 'G10-PRO-004', 'G10-PRO-005', 'G10-PRO-006', 'G10-PRO-007', 'G10-PRO-008', 'G10-PRO-009', 'G10-STA-001')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
