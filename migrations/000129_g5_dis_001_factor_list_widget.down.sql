BEGIN;

UPDATE task_type
SET widget_config = '{"template":{"template":"{p1}^{e1} {p2}^{e2} ..."}}'::jsonb
WHERE type_id = 'G5-DIS-001'
  AND answer_widget = 'STRUCTURED_CANON';

COMMIT;
