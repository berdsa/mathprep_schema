DELETE FROM task_type_template
WHERE type_id IN ('G9-ALG-001', 'G9-DIS-001', 'G9-FUN-001', 'G9-FUN-002', 'G9-FUN-003', 'G9-FUN-004', 'G9-FUN-005', 'G9-GEO-001', 'G9-GEO-002', 'G9-GEO-003')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
