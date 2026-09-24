DELETE FROM task_type_template
WHERE type_id IN ('G4-NUM-007', 'G4-NUM-008', 'G4-NUM-009', 'G4-NUM-010', 'G4-NUM-011', 'G4-NUM-012', 'G4-NUM-013', 'G4-NUM-014', 'G4-NUM-015', 'G4-NUM-016', 'G4-NUM-017', 'G4-NUM-018')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
