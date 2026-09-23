BEGIN;
INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES ('G5-FRA-003', 'ru-KZ', 'latex', '\frac{{a}}{{b}} + \frac{{c}}{{d}} = ?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version) DO UPDATE SET template_text = EXCLUDED.template_text;
COMMIT;
