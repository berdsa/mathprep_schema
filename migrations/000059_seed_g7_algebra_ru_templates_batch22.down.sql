DELETE FROM task_type_template
WHERE type_id IN ('G7-ALG-006', 'G7-ALG-007', 'G7-ALG-008', 'G7-ALG-009', 'G7-ALG-010', 'G7-ALG-011', 'G7-ALG-012', 'G7-ALG-013', 'G7-ALG-014', 'G7-ALG-015')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
