DELETE FROM task_type_template
WHERE type_id IN ('G2-NUM-001', 'G2-NUM-002', 'G2-NUM-003', 'G2-NUM-004', 'G2-NUM-005', 'G2-NUM-006', 'G2-NUM-007', 'G2-NUM-008', 'G2-NUM-009', 'G2-MEA-008')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
