DELETE FROM task_type_template
WHERE type_id IN ('U-ALG-001', 'U-ALG-002', 'U-ALG-003', 'U-CAL-001', 'U-CAL-004', 'U-CAL-006', 'U-CAL-007')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
