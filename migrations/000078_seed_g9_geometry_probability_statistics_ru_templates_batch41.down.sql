DELETE FROM task_type_template
WHERE type_id IN ('G9-GEO-004', 'G9-GEO-005', 'G9-GEO-006', 'G9-GEO-007', 'G9-GEO-008', 'G9-GEO-009', 'G9-GEO-010', 'G9-PRO-001', 'G9-STA-003', 'G9-STA-004')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
