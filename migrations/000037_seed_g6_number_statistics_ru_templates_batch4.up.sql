INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G6-NUM-001', 'ru-KZ', 'plaintext', 'Упростите отношение {{a}} : {{b}}.', '1.0.0-draft'),
    ('G6-NUM-003', 'ru-KZ', 'plaintext', 'Точка имеет координаты ({{x}}, {{y}}). Найдите её координату x.', '1.0.0-draft'),
    ('G6-NUM-004', 'ru-KZ', 'plaintext', 'Разделите {{a}} на {{b}}. Укажите частное и остаток.', '1.0.0-draft'),
    ('G6-NUM-005', 'ru-KZ', 'plaintext', 'Число расположено на {{n}} единиц левее нуля. Каково это число?', '1.0.0-draft'),
    ('G6-NUM-006', 'ru-KZ', 'plaintext', 'Вычислите модуль числа {{n}}.', '1.0.0-draft'),
    ('G6-NUM-007', 'ru-KZ', 'plaintext', 'Вычислите модуль разности {{a}} − {{b}}.', '1.0.0-draft'),
    ('G6-NUM-008', 'ru-KZ', 'plaintext', 'Всегда ли верно равенство a + b = b + a?', '1.0.0-draft'),
    ('G6-STA-001', 'ru-KZ', 'plaintext', 'Является ли вопрос «{{question}}» статистическим?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
