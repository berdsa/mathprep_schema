DELETE FROM task_type_template
WHERE type_id IN ('G8-ALG-003', 'G8-ALG-004', 'G8-FUN-001', 'G8-GEO-001', 'G8-GEO-002', 'G8-TRG-004')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
