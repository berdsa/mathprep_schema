DELETE FROM task_type_template
WHERE type_id IN (
    'G8-ALG-022', 'G8-ALG-023', 'G8-FUN-004', 'G8-GEO-008', 'G8-GEO-009',
    'G8-GEO-010', 'G8-GEO-011', 'G8-GEO-012', 'G8-GEO-013', 'G8-GEO-014', 'G8-GEO-015'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
