DELETE FROM task_type_template
WHERE type_id IN ('G6-NUM-001', 'G6-NUM-003', 'G6-NUM-004', 'G6-NUM-005', 'G6-NUM-006', 'G6-NUM-007', 'G6-NUM-008', 'G6-STA-001')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
