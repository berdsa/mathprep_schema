ALTER TABLE task_type
    ADD COLUMN answer_widget TEXT NOT NULL DEFAULT 'NUMERIC' REFERENCES answer_widget(code),
    ADD COLUMN widget_config JSONB;

ALTER TABLE task_type
    ALTER COLUMN answer_widget DROP DEFAULT;
