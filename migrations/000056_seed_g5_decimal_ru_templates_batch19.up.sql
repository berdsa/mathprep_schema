INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G5-DEC-001', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} {{operator}} {{b}}.', '1.0.0-draft'),
    ('G5-DEC-002', 'ru-KZ', 'plaintext', 'Запишите дробь {{a}}/100 в виде десятичной дроби.', '1.0.0-draft'),
    ('G5-DEC-003', 'ru-KZ', 'plaintext', 'Сравните {{a}} и {{b}}: <, > или =.', '1.0.0-draft'),
    ('G5-DEC-004', 'ru-KZ', 'plaintext', 'Верно ли, что {{a}}/10 = 0.{{a}}?', '1.0.0-draft'),
    ('G5-DEC-005', 'ru-KZ', 'plaintext', 'Какая цифра стоит в разряде {{place}} в числе {{n}}?', '1.0.0-draft'),
    ('G5-DEC-006', 'ru-KZ', 'plaintext', 'Запишите число {{n}} словами на английском языке; ожидаемый ответ указывает число тысячных.', '1.0.0-draft'),
    ('G5-DEC-007', 'ru-KZ', 'plaintext', 'Сравните {{a}} и {{b}}: <, > или =.', '1.0.0-draft'),
    ('G5-DEC-008', 'ru-KZ', 'plaintext', 'Округлите число {{n}} до ближайшего значения {{place}}.', '1.0.0-draft'),
    ('G5-DEC-009', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G5-DEC-010', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} − {{b}}.', '1.0.0-draft'),
    ('G5-DEC-011', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} × 10^{{k}}.', '1.0.0-draft'),
    ('G5-DEC-012', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} × {{b}}.', '1.0.0-draft'),
    ('G5-DEC-013', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} ÷ 10^{{k}}.', '1.0.0-draft'),
    ('G5-DEC-014', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} ÷ {{b}}.', '1.0.0-draft'),
    ('G5-DEC-015', 'ru-KZ', 'plaintext', 'Оцените сумму {{a}} + {{b}}, предварительно округлив каждое слагаемое до целого числа.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
