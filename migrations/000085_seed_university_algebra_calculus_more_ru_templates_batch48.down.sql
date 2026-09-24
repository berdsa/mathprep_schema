DELETE FROM task_type_template
WHERE type_id IN ('U-ALG-004', 'U-ALG-005', 'U-ALG-006', 'U-ALG-007', 'U-ALG-008', 'U-CAL-008', 'U-CAL-009', 'U-CAL-010', 'U-CAL-011', 'U-CAL-012')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
