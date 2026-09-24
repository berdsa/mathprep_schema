INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G4-GEO-001', 'ru-KZ', 'plaintext', 'Сколько концов у фигуры типа «{{object}}»?', '1.0.0-draft'),
    ('G4-GEO-002', 'ru-KZ', 'plaintext', 'Угол величиной {{a}}° является острым, прямым, тупым или развёрнутым? Ответьте кодом: acute, right, obtuse или straight.', '1.0.0-draft'),
    ('G4-GEO-003', 'ru-KZ', 'plaintext', 'Стороны треугольника равны {{a}}, {{b}} и {{c}}. Укажите тип треугольника кодом: scalene, isosceles или equilateral.', '1.0.0-draft'),
    ('G4-GEO-004', 'ru-KZ', 'plaintext', 'Углы треугольника равны {{a}}°, {{b}}° и {{c}}°. Укажите тип треугольника кодом: acute, right или obtuse.', '1.0.0-draft'),
    ('G4-GEO-005', 'ru-KZ', 'plaintext', 'У четырёхугольника {{description}}. Укажите его тип кодом: square, rectangle или rhombus.', '1.0.0-draft'),
    ('G4-GEO-007', 'ru-KZ', 'plaintext', 'Сколько углов у фигуры «{{shape}}»?', '1.0.0-draft'),
    ('G4-MEA-002', 'ru-KZ', 'plaintext', 'Переведите {{value}} {{from_unit}} в {{to_unit}}.', '1.0.0-draft'),
    ('G4-MEA-003', 'ru-KZ', 'plaintext', 'Переведите {{value}} м в сантиметры.', '1.0.0-draft'),
    ('G4-MEA-004', 'ru-KZ', 'plaintext', 'Переведите {{value}} см в метры. Запишите ответ дробью со знаменателем 100.', '1.0.0-draft'),
    ('G4-MEA-005', 'ru-KZ', 'plaintext', 'Пройдено {{a}} км, затем {{b}} м. Найдите общую длину в метрах.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
