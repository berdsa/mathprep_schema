DELETE FROM task_type_template
WHERE type_id IN (
    'G2-NUM-011', 'G2-NUM-012', 'G2-NUM-013', 'G2-NUM-014', 'G2-NUM-015',
    'G2-NUM-016', 'G2-NUM-017', 'G2-NUM-018', 'G2-NUM-019', 'G2-NUM-020'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
