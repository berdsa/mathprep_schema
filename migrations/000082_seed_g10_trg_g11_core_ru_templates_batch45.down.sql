DELETE FROM task_type_template
WHERE type_id IN ('G10-TRG-001', 'G11-ALG-001', 'G11-FUN-001', 'G11-LOG-001', 'G11-MAT-001', 'G11-MAT-002', 'G11-NUM-001', 'G11-PRO-001', 'G11-STA-001', 'G11-STA-002')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
