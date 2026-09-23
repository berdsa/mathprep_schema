BEGIN;
UPDATE task_type SET widget_config = '{"rows":2,"columns":2,"cell_label":"entry"}'::jsonb WHERE type_id = 'G11-MAT-001';
UPDATE task_type SET widget_config = '{"rows":2,"columns":2,"cell_label":"entry"}'::jsonb WHERE type_id = 'U-MAT-003';
COMMIT;
