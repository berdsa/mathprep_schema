DELETE FROM task_type_template
WHERE type_id IN (
    'G1-NUM-021', 'G1-NUM-022', 'G1-NUM-023', 'G1-NUM-024', 'G1-NUM-025',
    'G1-NUM-026', 'G1-MEA-001', 'G1-MEA-002', 'G1-MEA-003', 'G1-MEA-004'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
