DELETE FROM task_type_template
WHERE type_id IN ('G6-FRA-011', 'G6-FRA-012', 'G6-FRA-013', 'G6-FRA-014', 'G6-FRA-015', 'G6-GEO-001', 'G6-GEO-002', 'G6-GEO-003', 'G6-GEO-004', 'G6-GEO-005')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
