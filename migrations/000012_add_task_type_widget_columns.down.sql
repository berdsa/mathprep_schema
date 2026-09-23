ALTER TABLE task_type
    DROP COLUMN IF EXISTS widget_config,
    DROP COLUMN IF EXISTS answer_widget;
