INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G4-MEA-006', 'ru-KZ', 'plaintext', 'Начало: {{h1}}:{{m1}}. Окончание: {{h2}}:{{m2}}. Сколько минут прошло?', '1.0.0-draft'),
    ('G4-MEA-007', 'ru-KZ', 'plaintext', 'Объём резервуара {{a}} л, заполнено {{b}} л. Сколько литров нужно добавить до полного объёма?', '1.0.0-draft'),
    ('G4-MEA-008', 'ru-KZ', 'plaintext', 'Масса одного мешка {{a}} кг, другого — {{b}} г. Найдите общую массу в граммах.', '1.0.0-draft'),
    ('G4-MEA-009', 'ru-KZ', 'plaintext', 'Длина и ширина прямоугольника равны {{a}} и {{b}}. Найдите его площадь.', '1.0.0-draft'),
    ('G4-MEA-010', 'ru-KZ', 'plaintext', 'Длина и ширина прямоугольника равны {{a}} и {{b}}. Найдите его периметр.', '1.0.0-draft'),
    ('G4-MEA-011', 'ru-KZ', 'plaintext', 'Фигура Г-образной формы составлена из двух прямоугольников размером {{a}} × {{b}} и {{c}} × {{d}}. Найдите общую площадь.', '1.0.0-draft'),
    ('G4-MEA-012', 'ru-KZ', 'plaintext', 'Длины внешних сторон Г-образной фигуры: {{a}}, {{b}}, {{c}}, {{d}}, {{e}} и {{f}}. Найдите периметр.', '1.0.0-draft'),
    ('G4-STA-001', 'ru-KZ', 'plaintext', 'Значения на линейной диаграмме: {{values}}. Найдите их сумму.', '1.0.0-draft'),
    ('G4-MEA-013', 'ru-KZ', 'plaintext', 'Угол равен {{a}}°. Укажите его тип кодом: acute, right или obtuse.', '1.0.0-draft'),
    ('G4-MEA-014', 'ru-KZ', 'plaintext', 'Углы {{a}}° и b° образуют развёрнутый угол. Найдите b.', '1.0.0-draft'),
    ('G4-MEA-015', 'ru-KZ', 'plaintext', 'Три угла составляют 180°. Два из них равны {{a}}° и {{b}}°. Найдите третий угол.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
