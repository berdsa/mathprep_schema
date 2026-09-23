DELETE FROM task_type_template
WHERE type_id IN (
    'G1-GEO-001', 'G1-GEO-002', 'G1-GEO-003', 'G1-GEO-004', 'G1-GEO-005',
    'G1-GEO-006', 'G1-GEO-007', 'G1-GEO-008', 'G1-GEO-009', 'G2-NUM-010'
)
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
