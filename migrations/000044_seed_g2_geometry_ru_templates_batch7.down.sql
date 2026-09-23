DELETE FROM task_type_template
WHERE type_id IN (
    'G2-GEO-011', 'G2-GEO-012', 'G2-GEO-013', 'G2-GEO-014', 'G2-GEO-015',
    'G2-GEO-016', 'G2-GEO-017', 'G2-GEO-018', 'G2-GEO-019', 'G2-GEO-020'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
