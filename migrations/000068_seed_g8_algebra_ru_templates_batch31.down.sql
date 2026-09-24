DELETE FROM task_type_template
WHERE type_id IN (
    'G8-ALG-010', 'G8-ALG-011', 'G8-ALG-012', 'G8-ALG-013', 'G8-ALG-015',
    'G8-ALG-016', 'G8-ALG-017', 'G8-ALG-018', 'G8-ALG-019', 'G8-ALG-021'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
