INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-NUM-037', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} × ({{b}} + {{c}}).', '1.0.0-draft'),
    ('G3-NUM-038', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число будет следующим?', '1.0.0-draft'),
    ('G3-NUM-039', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число будет следующим?', '1.0.0-draft'),
    ('G3-NUM-040', 'ru-KZ', 'plaintext', 'Верно ли равенство {{a}} × {{b}} = {{c}}?', '1.0.0-draft'),
    ('G3-NUM-041', 'ru-KZ', 'plaintext', 'Сравните {{a}} × {{b}} и {{c}}. Укажите знак: <, > или =.', '1.0.0-draft'),
    ('G3-NUM-042', 'ru-KZ', 'plaintext', 'Округлите число {{n}} до ближайшего десятка.', '1.0.0-draft'),
    ('G3-NUM-043', 'ru-KZ', 'plaintext', 'Округлите число {{n}} до ближайшей сотни.', '1.0.0-draft'),
    ('G3-NUM-044', 'ru-KZ', 'plaintext', 'Вычислите сумму: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G3-NUM-045', 'ru-KZ', 'plaintext', 'Вычислите разность: {{a}} − {{b}}.', '1.0.0-draft'),
    ('G3-NUM-046', 'ru-KZ', 'plaintext', 'Вычислите произведение: {{a}} × {{b}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
