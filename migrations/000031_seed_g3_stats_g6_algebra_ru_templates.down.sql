DELETE FROM task_type_template
WHERE type_id IN ('G3-NUM-047', 'G3-STA-001', 'G3-STA-002', 'G3-STA-003', 'G3-STA-004', 'G6-ALG-001', 'G6-ALG-002', 'G6-ALG-003', 'G6-ALG-004', 'G6-ALG-005')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
