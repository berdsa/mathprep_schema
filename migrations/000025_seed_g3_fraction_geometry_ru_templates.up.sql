INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-FRA-009', 'ru-KZ', 'plaintext', 'Закрашено частей: {{s}} из {{d}}. Какая дробь показывает закрашенную долю?', '1.0.0-draft'),
    ('G3-FRA-010', 'ru-KZ', 'plaintext', 'Сравните дроби 1/{{a}} и 1/{{b}}. Укажите знак: <, > или =.', '1.0.0-draft'),
    ('G3-FRA-011', 'ru-KZ', 'plaintext', 'Заполните пропуск: {{a}}/{{b}} = ?/{{c}}.', '1.0.0-draft'),
    ('G3-FRA-012', 'ru-KZ', 'plaintext', 'На отрезке от 0 до 1 отмечено {{p}} из {{d}} равных делений. Какая дробь соответствует этой отметке?', '1.0.0-draft'),
    ('G3-FRA-013', 'ru-KZ', 'plaintext', 'Запишите число {{n}} в виде дроби со знаменателем {{d}}.', '1.0.0-draft'),
    ('G3-FRA-014', 'ru-KZ', 'plaintext', 'Сравните дроби {{a}}/{{b}} и {{c}}/{{d}}. Укажите знак: <, > или =.', '1.0.0-draft'),
    ('G3-GEO-001', 'ru-KZ', 'plaintext', 'Закрашено частей: {{s}} из {{d}} равных. Какая дробь показывает закрашенную долю?', '1.0.0-draft'),
    ('G3-GEO-002', 'ru-KZ', 'plaintext', 'Сравните площади прямоугольников размером {{a}} × {{b}} и {{c}} × {{d}}. Укажите знак: <, > или =.', '1.0.0-draft'),
    ('G3-GEO-003', 'ru-KZ', 'plaintext', 'Сравните периметры прямоугольников размером {{a}} × {{b}} и {{c}} × {{d}}. Укажите знак: <, > или =.', '1.0.0-draft'),
    ('G3-GEO-004', 'ru-KZ', 'plaintext', 'Фигура: {{shape}}. Является ли она четырёхугольником?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
