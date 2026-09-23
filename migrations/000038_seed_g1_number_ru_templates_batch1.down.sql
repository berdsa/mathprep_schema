DELETE FROM task_type_template
WHERE type_id IN ('G1-NUM-011', 'G1-NUM-012', 'G1-NUM-013', 'G1-NUM-014', 'G1-NUM-015', 'G1-NUM-016', 'G1-NUM-017', 'G1-NUM-018', 'G1-NUM-019', 'G1-NUM-020')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
