DELETE FROM task_type_template
WHERE type_id IN (
    'G1-MEA-005', 'G1-MEA-006', 'G1-MEA-007',
    'G1-STA-001', 'G1-STA-002', 'G1-STA-003',
    'G1-MEA-008', 'G1-MEA-009', 'G1-MEA-010', 'G1-STA-004'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
