INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G6-FRA-011', 'ru-KZ', 'plaintext', 'Упорядочьте дроби от наименьшей к наибольшей: {{fractions}}.', '1.0.0-draft'),
    ('G6-FRA-012', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} + {{c}}/{{d}}.', '1.0.0-draft'),
    ('G6-FRA-013', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} × {{c}}/{{d}}.', '1.0.0-draft'),
    ('G6-FRA-014', 'ru-KZ', 'plaintext', 'Температура была {{a}} °C. Она снизилась на {{b}} °C. Какова новая температура?', '1.0.0-draft'),
    ('G6-FRA-015', 'ru-KZ', 'plaintext', 'Найдите число, противоположное дроби {{a}}/{{b}}.', '1.0.0-draft'),
    ('G6-GEO-001', 'ru-KZ', 'plaintext', 'В какой четверти или на какой оси находится точка ({{x}}, {{y}})?', '1.0.0-draft'),
    ('G6-GEO-002', 'ru-KZ', 'plaintext', 'Найдите расстояние между точками ({{x1}}, {{y1}}) и ({{x2}}, {{y2}}).', '1.0.0-draft'),
    ('G6-GEO-003', 'ru-KZ', 'plaintext', 'Для круга радиуса {{r}} вычислите {{target}}. Используйте десятичное приближение с π≈3.141592653589793.', '1.0.0-draft'),
    ('G6-GEO-004', 'ru-KZ', 'plaintext', 'Точка имеет координаты ({{x}}, {{y}}). Найдите сумму x + y.', '1.0.0-draft'),
    ('G6-GEO-005', 'ru-KZ', 'plaintext', 'Точка с координатами ({{x}}, {{y}}) отмечена на координатной плоскости. Чему равна её координата y?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
