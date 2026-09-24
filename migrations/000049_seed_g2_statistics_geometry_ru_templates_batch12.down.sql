DELETE FROM task_type_template
WHERE type_id IN (
    'G2-STA-002', 'G2-STA-003', 'G2-STA-004', 'G2-STA-005',
    'G2-MEA-018', 'G2-MEA-019', 'G2-GEO-021', 'G2-GEO-022',
    'G2-GEO-023', 'G2-GEO-024'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
