DELETE FROM task_type_template
WHERE type_id IN ('G3-GEO-005', 'G3-GEO-006', 'G3-GEO-007', 'G3-GEO-008', 'G3-GEO-009', 'G3-MEA-009', 'G3-MEA-010', 'G3-MEA-011', 'G3-MEA-012', 'G3-MEA-013')
  AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
