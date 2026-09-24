INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G11-STA-003', 'ru-KZ', 'plaintext', 'Используя стандартное нормальное распределение, найдите P(Z < {{z}}).', '1.0.0-draft'),
    ('G11-STA-004', 'ru-KZ', 'plaintext', 'Для генеральной совокупности σ = {{sigma}} и объёма выборки n = {{n}} найдите стандартную ошибку.', '1.0.0-draft'),
    ('G11-STA-005', 'ru-KZ', 'plaintext', 'Найдите доверительный интервал для среднего значения {{mean}} с шириной {{z}} стандартных ошибок при σ = {{sigma}} и n = {{n}}.', '1.0.0-draft'),
    ('G11-STA-006', 'ru-KZ', 'plaintext', 'Найдите z = (x̄ − μ)/(σ/√n), если x̄ = {{xbar}}, μ = {{mu}}, σ = {{sigma}}, n = {{n}}.', '1.0.0-draft'),
    ('G11-TRG-001', 'ru-KZ', 'plaintext', 'Решите sin(x) = {{value}} при 0° ≤ x < 360°. Укажите все решения.', '1.0.0-draft'),
    ('G11-VEC-001', 'ru-KZ', 'plaintext', 'Даны векторы u = ({{u1}}; {{u2}}) и v = ({{v1}}; {{v2}}). Найдите их скалярное произведение.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
