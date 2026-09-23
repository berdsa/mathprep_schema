INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-NUM-001', 'ru-KZ', 'plaintext', 'Вычислите сумму: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G3-NUM-004', 'ru-KZ', 'plaintext', 'Вычислите разность: {{a}} − {{b}}.', '1.0.0-draft'),
    ('G3-NUM-005', 'ru-KZ', 'plaintext', 'Вычислите сумму: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G3-NUM-008', 'ru-KZ', 'plaintext', 'Какое число на 100 меньше {{n}}?', '1.0.0-draft'),
    ('G3-NUM-009', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число будет следующим?', '1.0.0-draft'),
    ('G3-NUM-010', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число будет следующим?', '1.0.0-draft'),
    ('G3-NUM-012', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число будет следующим?', '1.0.0-draft'),
    ('G3-NUM-014', 'ru-KZ', 'plaintext', 'Если {{a}} × {{b}} = c, чему равно {{b}} × {{a}}?', '1.0.0-draft'),
    ('G6-ALG-006', 'ru-KZ', 'plaintext', 'Решите неравенство: x + {{a}} < {{b}}.', '1.0.0-draft'),
    ('G6-ALG-007', 'ru-KZ', 'plaintext', 'Проверьте, является ли x = {{x}} решением уравнения {{b}}x + {{a}} = {{d}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
