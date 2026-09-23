DELETE FROM task_type_template
WHERE type_id IN ('G3-NUM-001', 'G3-NUM-004', 'G3-NUM-005', 'G3-NUM-008', 'G3-NUM-009', 'G3-NUM-010', 'G3-NUM-012', 'G3-NUM-014', 'G6-ALG-006', 'G6-ALG-007')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
