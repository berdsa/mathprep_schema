DELETE FROM task_type_template
WHERE type_id IN ('U-CAL-013', 'U-CAL-014', 'U-CAL-015', 'U-CAL-016', 'U-CAL-017', 'U-CAL-018', 'U-CAL-019', 'U-CAL-020', 'U-CAL-021', 'U-CAL-022')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
