ALTER TABLE task_type_template
    ADD COLUMN render_target TEXT NOT NULL DEFAULT 'plaintext' REFERENCES render_target(code);

ALTER TABLE task_type_template
    ALTER COLUMN render_target DROP DEFAULT;

ALTER TABLE task_type_template
    DROP CONSTRAINT task_type_template_pkey,
    ADD PRIMARY KEY (type_id, locale, render_target, spec_version);

DROP INDEX IF EXISTS task_type_template_lookup_idx;
CREATE INDEX task_type_template_lookup_idx
    ON task_type_template (type_id, locale, render_target);
