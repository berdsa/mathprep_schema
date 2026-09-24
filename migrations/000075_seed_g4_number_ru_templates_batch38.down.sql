DELETE FROM task_type_template
WHERE type_id IN ('G4-NUM-019', 'G4-NUM-020', 'G4-NUM-021', 'G4-NUM-022', 'G4-NUM-023', 'G4-NUM-024', 'G4-NUM-025', 'G4-NUM-026', 'G4-NUM-027', 'G4-NUM-028')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
