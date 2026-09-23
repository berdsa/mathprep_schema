DELETE FROM task_type_template
WHERE type_id IN ('G6-GEO-006', 'G6-GEO-007', 'G6-GEO-008', 'G6-GEO-009', 'G6-GEO-010', 'G6-GEO-011', 'G6-GEO-012', 'G6-GEO-013', 'G6-GEO-014', 'G6-GEO-015')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
