DELETE FROM task_type_template
WHERE type_id IN (
    'G2-NUM-021', 'G2-NUM-022', 'G2-NUM-023', 'G2-NUM-024', 'G2-NUM-025',
    'G2-NUM-026', 'G2-NUM-027', 'G2-NUM-028', 'G2-NUM-029', 'G2-NUM-030'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
