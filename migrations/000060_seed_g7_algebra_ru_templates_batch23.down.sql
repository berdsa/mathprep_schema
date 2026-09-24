DELETE FROM task_type_template
WHERE type_id IN ('G7-ALG-016', 'G7-ALG-017', 'G7-ALG-018', 'G7-ALG-019', 'G7-ALG-020', 'G7-ALG-021', 'G7-ALG-022', 'G7-ALG-023', 'G7-ALG-024', 'G7-ALG-025')
AND locale = 'ru-KZ' AND render_target = 'plaintext' AND spec_version = '1.0.0-draft';
