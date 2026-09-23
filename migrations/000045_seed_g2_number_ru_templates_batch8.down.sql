DELETE FROM task_type_template
WHERE type_id IN (
    'G2-NUM-031', 'G2-NUM-032', 'G2-NUM-033', 'G2-NUM-034', 'G2-NUM-035',
    'G2-NUM-036', 'G2-NUM-037', 'G2-NUM-038', 'G2-NUM-039', 'G2-NUM-040'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
