INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G8-ALG-003', 'ru-KZ', 'plaintext', 'Решите квадратное уравнение x² + ({{b}})x + ({{c}}) = 0.', '1.0.0-draft'),
    ('G8-ALG-004', 'ru-KZ', 'plaintext', 'Запишите правый луч множества решений неравенства x² + ({{b}})x + ({{c}}) > 0.', '1.0.0-draft'),
    ('G8-FUN-001', 'ru-KZ', 'plaintext', 'Функция задана формулой f(x) = ({{a}})x² + ({{b}})x + ({{c}}). Найдите f({{x}}).', '1.0.0-draft'),
    ('G8-GEO-001', 'ru-KZ', 'plaintext', 'Катеты прямоугольного треугольника равны {{a}} и {{b}}. Найдите длину гипотенузы.', '1.0.0-draft'),
    ('G8-GEO-002', 'ru-KZ', 'plaintext', 'Найдите расстояние между точками ({{x1}}, {{y1}}) и ({{x2}}, {{y2}}).', '1.0.0-draft'),
    ('G8-TRG-004', 'ru-KZ', 'plaintext', 'Вычислите значение {{function}}({{angle}}°).', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
