DELETE FROM task_type_template
WHERE type_id IN ('G11-STA-003', 'G11-STA-004', 'G11-STA-005', 'G11-STA-006', 'G11-TRG-001', 'G11-VEC-001')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
