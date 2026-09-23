DELETE FROM task_type_template
WHERE type_id IN ('G3-NUM-037', 'G3-NUM-038', 'G3-NUM-039', 'G3-NUM-040', 'G3-NUM-041', 'G3-NUM-042', 'G3-NUM-043', 'G3-NUM-044', 'G3-NUM-045', 'G3-NUM-046')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
