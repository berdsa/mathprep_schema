DELETE FROM task_type_template
WHERE type_id IN ('G9-VEC-001', 'G9-VEC-002', 'G9-TRG-001')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
