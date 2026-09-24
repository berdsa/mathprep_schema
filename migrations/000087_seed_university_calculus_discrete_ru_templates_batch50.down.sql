DELETE FROM task_type_template
WHERE type_id IN ('U-CAL-023', 'U-CAL-024', 'U-CAL-025', 'U-DIS-001', 'U-DIS-002', 'U-DIS-003', 'U-DIS-004', 'U-DIS-005', 'U-DIS-006', 'U-DIS-007', 'U-DIS-008')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
