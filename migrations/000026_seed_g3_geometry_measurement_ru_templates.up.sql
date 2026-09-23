INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-GEO-005', 'ru-KZ', 'plaintext', 'Фигура: {{shape}}. Есть ли у неё прямой угол?', '1.0.0-draft'),
    ('G3-GEO-006', 'ru-KZ', 'plaintext', 'Фигура: {{shape}}. Сколько пар параллельных сторон у неё?', '1.0.0-draft'),
    ('G3-GEO-007', 'ru-KZ', 'plaintext', 'Выберите многоугольник с {{n}} сторонами: треугольник, квадрат, пятиугольник, шестиугольник или восьмиугольник.', '1.0.0-draft'),
    ('G3-GEO-008', 'ru-KZ', 'plaintext', 'Сколько сторон у треугольника и квадрата вместе?', '1.0.0-draft'),
    ('G3-GEO-009', 'ru-KZ', 'plaintext', 'Фигура разделена на {{d}} равных частей. Сколько частей получилось?', '1.0.0-draft'),
    ('G3-MEA-009', 'ru-KZ', 'plaintext', 'Длины двух сторон прямоугольника: {{a}} и {{b}}. Найдите периметр.', '1.0.0-draft'),
    ('G3-MEA-010', 'ru-KZ', 'plaintext', 'Длины сторон прямоугольника: {{a}} и {{b}}. Найдите площадь.', '1.0.0-draft'),
    ('G3-MEA-011', 'ru-KZ', 'plaintext', 'На часах {{h}}:{{minute}}. Запишите показанное время в формате Ч:ММ.', '1.0.0-draft'),
    ('G3-MEA-012', 'ru-KZ', 'plaintext', 'Начало: {{h}}:{{minute_start}}. Конец: {{h}}:{{minute_end}}. Сколько минут прошло?', '1.0.0-draft'),
    ('G3-MEA-013', 'ru-KZ', 'plaintext', 'Начало: {{h1}}:{{minute_start}}. Конец: {{h2}}:{{minute_end}}. Сколько минут прошло?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
