INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G9-VEC-001', 'ru-KZ', 'plaintext', 'Даны векторы u = ({{u1}}; {{u2}}) и v = ({{v1}}; {{v2}}). Найдите {{operation}}.', '1.0.0-draft'),
    ('G9-VEC-002', 'ru-KZ', 'plaintext', 'Даны векторы u = ({{u1}}; {{u2}}) и v = ({{v1}}; {{v2}}). Найдите сумму u + v.', '1.0.0-draft'),
    ('G9-TRG-001', 'ru-KZ', 'plaintext', 'В треугольнике сторона a = {{a}} лежит напротив угла A = {{A}}°, а угол B равен {{B}}°. Найдите сторону b по теореме синусов.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
