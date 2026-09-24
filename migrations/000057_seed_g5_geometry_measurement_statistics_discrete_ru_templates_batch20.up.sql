INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G5-GEO-001', 'ru-KZ', 'plaintext', 'Верно ли, что каждый {{shape}} является {{category}}? Ответьте true или false.', '1.0.0-draft'),
    ('G5-GEO-002', 'ru-KZ', 'plaintext', 'Сколько прямых углов у фигуры «{{shape}}»?', '1.0.0-draft'),
    ('G5-GEO-003', 'ru-KZ', 'plaintext', 'Прямоугольный параллелепипед имеет размеры {{a}} × {{b}} × {{c}}. Найдите его объём.', '1.0.0-draft'),
    ('G5-MEA-001', 'ru-KZ', 'plaintext', 'Размеры прямоугольного параллелепипеда: {{a}} × {{b}} × {{c}}. Найдите объём.', '1.0.0-draft'),
    ('G5-MEA-002', 'ru-KZ', 'plaintext', 'Переведите {{a}} м в сантиметры.', '1.0.0-draft'),
    ('G5-MEA-003', 'ru-KZ', 'plaintext', 'Переведите длину {{a}} ft в дюймы.', '1.0.0-draft'),
    ('G5-MEA-004', 'ru-KZ', 'plaintext', 'Коробка заполнена единичными кубами в количестве {{a}} × {{b}} × {{c}}. Найдите объём.', '1.0.0-draft'),
    ('G5-MEA-005', 'ru-KZ', 'plaintext', 'Размеры двух прямоугольных параллелепипедов: {{a}} × {{b}} × {{c}} и {{d}} × {{e}} × {{f}}. Найдите сумму их объёмов.', '1.0.0-draft'),
    ('G5-MEA-006', 'ru-KZ', 'plaintext', 'Сравните объёмы {{a}} × {{b}} × {{c}} и {{d}} × {{e}} × {{f}}. Укажите больший объём кодом: first или second.', '1.0.0-draft'),
    ('G5-MEA-007', 'ru-KZ', 'plaintext', 'Размеры резервуара {{a}} × {{b}} × {{c}}. Жидкость заполняет его на высоту {{h}}. Найдите объём жидкости.', '1.0.0-draft'),
    ('G5-STA-001', 'ru-KZ', 'plaintext', 'Значения: {{values}}. Найдите их сумму.', '1.0.0-draft'),
    ('G5-DIS-001', 'ru-KZ', 'plaintext', 'Разложите число {{n}} на простые множители.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
