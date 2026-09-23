DELETE FROM task_type_template
WHERE type_id IN ('G3-NUM-026', 'G3-NUM-027', 'G3-NUM-028', 'G3-NUM-029', 'G3-NUM-030', 'G3-NUM-031', 'G3-NUM-032', 'G3-NUM-033', 'G3-NUM-034', 'G3-NUM-035', 'G3-NUM-036')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
