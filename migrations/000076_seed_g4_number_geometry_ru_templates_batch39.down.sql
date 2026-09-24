DELETE FROM task_type_template
WHERE type_id IN ('G4-NUM-029', 'G4-NUM-030', 'G4-NUM-031', 'G4-NUM-032', 'G4-NUM-033', 'G4-NUM-034', 'G4-NUM-035', 'G4-NUM-036', 'G4-GEO-006')
  AND locale = 'ru-KZ'
  AND render_target = 'plaintext'
  AND spec_version = '1.0.0-draft';
