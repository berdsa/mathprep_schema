DELETE FROM task_type_template
WHERE type_id IN ('G3-NUM-016', 'G3-NUM-017', 'G3-NUM-018', 'G3-NUM-019', 'G3-NUM-020', 'G3-NUM-021', 'G3-NUM-022', 'G3-NUM-023', 'G3-NUM-024', 'G3-NUM-025')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
