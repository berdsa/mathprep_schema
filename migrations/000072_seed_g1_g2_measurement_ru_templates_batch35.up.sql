INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G1-NUM-002', 'ru-KZ', 'plaintext', 'Вычислите {{a}} − {{b}}.', '1.0.0-draft'),
    ('G1-NUM-003', 'ru-KZ', 'plaintext', 'Сравните числа {{a}} и {{b}}. Впишите знак <, > или =.', '1.0.0-draft'),
    ('G1-NUM-004', 'ru-KZ', 'plaintext', 'Найдите неизвестное слагаемое: {{a}} + ? = {{c}}.', '1.0.0-draft'),
    ('G1-NUM-007', 'ru-KZ', 'plaintext', 'Расположите числа по возрастанию: {{values}}.', '1.0.0-draft'),
    ('G2-MEA-001', 'ru-KZ', 'plaintext', 'Длины двух досок: {{a}} см и {{b}} см. Найдите их общую длину.', '1.0.0-draft'),
    ('G2-MEA-002', 'ru-KZ', 'plaintext', 'Длина верёвки — {{a}} см. Отрезали {{b}} см. Найдите оставшуюся длину.', '1.0.0-draft'),
    ('G2-MEA-003', 'ru-KZ', 'plaintext', 'Сравните длины: {{a}} см и {{b}} см. Впишите знак <, > или =.', '1.0.0-draft'),
    ('G2-MEA-004', 'ru-KZ', 'plaintext', 'Расположите значения длин по возрастанию: {{a}} см, {{b}} см, {{c}} см.', '1.0.0-draft'),
    ('G2-MEA-005', 'ru-KZ', 'plaintext', 'Длины трёх отрезков: {{a}} см, {{b}} см и {{c}} см. Найдите их общую длину.', '1.0.0-draft'),
    ('G2-GEO-010', 'ru-KZ', 'plaintext', 'Сколько сторон у {{shape}}?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
