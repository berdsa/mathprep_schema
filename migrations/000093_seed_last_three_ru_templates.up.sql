INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
 ('G2-MEA-006','ru-KZ','plaintext','Сейчас {{h}}:00. Сколько минут после полуночи будет через {{k}} минут?','1.0.0-draft'),
 ('G2-MEA-007','ru-KZ','plaintext','Сейчас {{h}}:{{m}}. Сколько минут после полуночи было на {{k}} минут раньше?','1.0.0-draft'),
 ('G7-GEO-021','ru-KZ','plaintext','Биссектриса делит угол величиной {{angle}}° на две равные части. Найдите величину каждой части.','1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text=EXCLUDED.template_text;
