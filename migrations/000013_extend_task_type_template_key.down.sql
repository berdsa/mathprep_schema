DROP INDEX IF EXISTS task_type_template_lookup_idx;
ALTER TABLE task_type_template
    DROP CONSTRAINT task_type_template_pkey,
    ADD PRIMARY KEY (type_id, locale, spec_version);
ALTER TABLE task_type_template
    DROP COLUMN IF EXISTS render_target;
CREATE INDEX task_type_template_lookup_idx
    ON task_type_template (type_id, locale);
