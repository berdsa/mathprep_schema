DELETE FROM task_type_template
WHERE type_id IN (
    'G2-NUM-051', 'G2-NUM-052', 'G2-NUM-053', 'G2-NUM-054', 'G2-NUM-055', 'G2-NUM-056',
    'G2-NUM-057', 'G2-NUM-058', 'G2-NUM-059', 'G2-NUM-060', 'G2-NUM-061', 'G2-NUM-062'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
