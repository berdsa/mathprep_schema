DELETE FROM task_type_template
WHERE type_id IN (
    'G2-NUM-041', 'G2-NUM-042', 'G2-NUM-043', 'G2-NUM-044', 'G2-NUM-045',
    'G2-NUM-046', 'G2-NUM-047', 'G2-NUM-048', 'G2-NUM-049', 'G2-NUM-050'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
