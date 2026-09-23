INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G1-GEO-001', 'ru-KZ', 'plaintext', 'Фигура «{{shape}}» — плоская или объёмная? Введите 2D или 3D.', '1.0.0-draft'),
    ('G1-GEO-002', 'ru-KZ', 'plaintext', 'Фигура разделена на 2 равные части. Какую дробь составляет одна часть?', '1.0.0-draft'),
    ('G1-GEO-003', 'ru-KZ', 'plaintext', 'Фигура разделена на 4 равные части. Какую дробь составляет одна часть?', '1.0.0-draft'),
    ('G1-GEO-004', 'ru-KZ', 'plaintext', 'Число закрашенных частей: {{s}} из {{d}}. Какая дробь фигуры закрашена?', '1.0.0-draft'),
    ('G1-GEO-005', 'ru-KZ', 'plaintext', 'Фигура разделена на {{parts}} равные части. Сколько всего частей?', '1.0.0-draft'),
    ('G1-GEO-006', 'ru-KZ', 'plaintext', 'У треугольника 3 стороны? Введите код TRUE или FALSE.', '1.0.0-draft'),
    ('G1-GEO-007', 'ru-KZ', 'plaintext', 'У какой фигуры больше сторон: у треугольника или квадрата? Введите код: triangle или square.', '1.0.0-draft'),
    ('G1-GEO-008', 'ru-KZ', 'plaintext', 'Какая фигура имеет 4 равные стороны и четыре прямых угла? Введите один из кодов: square, rectangle, triangle, circle.', '1.0.0-draft'),
    ('G1-GEO-009', 'ru-KZ', 'plaintext', 'Сколько всего сторон у треугольника и квадрата?', '1.0.0-draft'),
    ('G2-NUM-010', 'ru-KZ', 'plaintext', 'Какое число следует за {{n}}?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
