DELETE FROM task_type_template
WHERE type_id IN ('G3-MEA-014', 'G3-MEA-015', 'G3-MEA-016', 'G3-MEA-017', 'G3-MEA-018', 'G3-NUM-006', 'G3-NUM-007', 'G3-NUM-011', 'G3-NUM-013', 'G3-NUM-015')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
