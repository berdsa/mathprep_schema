DELETE FROM task_type_template
WHERE type_id IN (
    'G8-GEO-016', 'G8-GEO-017', 'G8-GEO-018', 'G8-GEO-019', 'G8-GEO-020',
    'G8-GEO-021', 'G8-GEO-022', 'G8-GEO-023', 'G8-FUN-005', 'G8-FUN-006'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
