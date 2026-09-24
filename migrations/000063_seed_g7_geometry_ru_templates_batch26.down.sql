DELETE FROM task_type_template
WHERE type_id IN ('G7-GEO-011', 'G7-GEO-013', 'G7-GEO-014', 'G7-GEO-015', 'G7-GEO-016', 'G7-GEO-017', 'G7-GEO-018', 'G7-GEO-019', 'G7-GEO-020', 'G7-GEO-022')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
