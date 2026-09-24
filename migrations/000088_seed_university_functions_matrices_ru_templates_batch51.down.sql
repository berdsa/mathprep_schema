DELETE FROM task_type_template
WHERE type_id IN ('U-CAL-026', 'U-FUN-001', 'U-FUN-002', 'U-MAT-001', 'U-MAT-002', 'U-MAT-003', 'U-MAT-004', 'U-MAT-005', 'U-MAT-006', 'U-MAT-007')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
