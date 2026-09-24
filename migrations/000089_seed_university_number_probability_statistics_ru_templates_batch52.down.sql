DELETE FROM task_type_template
WHERE type_id IN ('U-NUM-001', 'U-PRO-001', 'U-PRO-002', 'U-PRO-003', 'U-PRO-004', 'U-STA-001', 'U-STA-002', 'U-STA-003', 'U-STA-004', 'U-STA-005', 'U-STA-006', 'U-STA-007', 'U-STA-008', 'U-STA-009')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
