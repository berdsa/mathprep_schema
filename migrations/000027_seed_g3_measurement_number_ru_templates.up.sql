INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-MEA-014', 'ru-KZ', 'plaintext', 'Длина стола составляет {{a}} см. Сколько это миллиметров?', '1.0.0-draft'),
    ('G3-MEA-015', 'ru-KZ', 'plaintext', 'Объём бутылки составляет {{a}} л. Сколько это миллилитров?', '1.0.0-draft'),
    ('G3-MEA-016', 'ru-KZ', 'plaintext', 'Масса мешка составляет {{a}} кг. Сколько это граммов?', '1.0.0-draft'),
    ('G3-MEA-017', 'ru-KZ', 'plaintext', 'Прямоугольник покрыт квадратами: {{r}} рядов и {{c}} квадратов в каждом ряду. Найдите площадь в квадратных единицах.', '1.0.0-draft'),
    ('G3-MEA-018', 'ru-KZ', 'plaintext', 'Длины сторон многоугольника: {{sides}}. Найдите периметр.', '1.0.0-draft'),
    ('G3-NUM-006', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}} × {{c}} − {{d}} ÷ {{e}}.', '1.0.0-draft'),
    ('G3-NUM-007', 'ru-KZ', 'plaintext', 'Округлите число {{n}} до ближайшего разряда {{place}}.', '1.0.0-draft'),
    ('G3-NUM-011', 'ru-KZ', 'plaintext', 'Разделите {{a}} на {{b}}. Запишите частное и остаток через запятую.', '1.0.0-draft'),
    ('G3-NUM-013', 'ru-KZ', 'plaintext', 'Продолжите {{pattern}} последовательность: {{terms}}. Какое число будет следующим?', '1.0.0-draft'),
    ('G3-NUM-015', 'ru-KZ', 'plaintext', 'Заполните пропуск: {{a}} × ? = {{c}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
