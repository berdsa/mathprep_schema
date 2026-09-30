BEGIN;

-- The grader accepts the sorted prime-factor list with multiplicity, so the
-- student widget must capture that list as one canonical string.
UPDATE task_type
SET widget_config = '{"template":{"template":"{factors}"}}'::jsonb
WHERE type_id = 'G5-DIS-001'
  AND answer_widget = 'STRUCTURED_CANON';

COMMIT;
