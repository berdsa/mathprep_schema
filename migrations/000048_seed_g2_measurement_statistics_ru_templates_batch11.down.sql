DELETE FROM task_type_template
WHERE type_id IN (
    'G2-MEA-009', 'G2-MEA-010', 'G2-MEA-011', 'G2-MEA-012', 'G2-MEA-013',
    'G2-MEA-014', 'G2-MEA-015', 'G2-MEA-016', 'G2-MEA-017', 'G2-STA-001'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
