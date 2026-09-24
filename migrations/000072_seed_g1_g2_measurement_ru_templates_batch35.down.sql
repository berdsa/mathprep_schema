DELETE FROM task_type_template
WHERE type_id IN ('G1-NUM-002', 'G1-NUM-003', 'G1-NUM-004', 'G1-NUM-007', 'G2-MEA-001', 'G2-MEA-002', 'G2-MEA-003', 'G2-MEA-004', 'G2-MEA-005', 'G2-GEO-010')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
