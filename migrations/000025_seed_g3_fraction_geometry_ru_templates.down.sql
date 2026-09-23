DELETE FROM task_type_template
WHERE type_id IN ('G3-FRA-009', 'G3-FRA-010', 'G3-FRA-011', 'G3-FRA-012', 'G3-FRA-013', 'G3-FRA-014', 'G3-GEO-001', 'G3-GEO-002', 'G3-GEO-003', 'G3-GEO-004')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
