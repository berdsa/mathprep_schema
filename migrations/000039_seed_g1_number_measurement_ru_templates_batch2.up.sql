INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G1-NUM-021', 'ru-KZ', 'plaintext', 'Количество яблок до отдачи: ?. Отдали: {{b}}. Осталось: {{c}}. Найдите первоначальное количество.', '1.0.0-draft'),
    ('G1-NUM-022', 'ru-KZ', 'plaintext', 'Если {{a}} + {{b}} = {{c}}, чему равно {{b}} + {{a}}?', '1.0.0-draft'),
    ('G1-NUM-023', 'ru-KZ', 'plaintext', 'Если {{a}} + {{b}} = {{c}}, чему равно {{c}} − {{a}}?', '1.0.0-draft'),
    ('G1-NUM-024', 'ru-KZ', 'plaintext', 'Равенство {{a}} + {{b}} = {{c}} верно или неверно?', '1.0.0-draft'),
    ('G1-NUM-025', 'ru-KZ', 'plaintext', 'Количество яблок вначале: {{a}}. Добавили: {{b}}. Убрали: {{c}}. Сколько яблок осталось?', '1.0.0-draft'),
    ('G1-NUM-026', 'ru-KZ', 'plaintext', '{{a}} − {{b}} = ? (без перехода через десяток)', '1.0.0-draft'),
    ('G1-MEA-001', 'ru-KZ', 'plaintext', 'Длина первого отрезка: {{a}} см. Длина второго отрезка: {{b}} см. Какова общая длина?', '1.0.0-draft'),
    ('G1-MEA-002', 'ru-KZ', 'plaintext', 'Длина верёвки: {{a}} см. Отрезали: {{b}} см. Сколько сантиметров осталось?', '1.0.0-draft'),
    ('G1-MEA-003', 'ru-KZ', 'plaintext', 'Сравните {{a}} см и {{b}} см: <, > или =.', '1.0.0-draft'),
    ('G1-MEA-004', 'ru-KZ', 'plaintext', 'Расположите {{a}} см, {{b}} см и {{c}} см от меньшей длины к большей.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
