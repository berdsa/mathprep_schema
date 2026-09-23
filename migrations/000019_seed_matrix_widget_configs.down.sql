BEGIN;
UPDATE task_type SET widget_config = NULL WHERE type_id = 'G11-MAT-001';
UPDATE task_type SET widget_config = NULL WHERE type_id = 'U-MAT-003';
COMMIT;
