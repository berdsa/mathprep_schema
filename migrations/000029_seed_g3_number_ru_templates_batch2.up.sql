INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-NUM-026', 'ru-KZ', 'plaintext', 'Вычислите сумму: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G3-NUM-027', 'ru-KZ', 'plaintext', 'Вычислите разность: {{a}} − {{b}}.', '1.0.0-draft'),
    ('G3-NUM-028', 'ru-KZ', 'plaintext', 'Какое число на 100 больше {{n}}?', '1.0.0-draft'),
    ('G3-NUM-029', 'ru-KZ', 'plaintext', 'Какое число на 100 меньше {{n}}?', '1.0.0-draft'),
    ('G3-NUM-030', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число следующее?', '1.0.0-draft'),
    ('G3-NUM-031', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число следующее?', '1.0.0-draft'),
    ('G3-NUM-032', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число следующее?', '1.0.0-draft'),
    ('G3-NUM-033', 'ru-KZ', 'plaintext', 'Продолжите последовательность: {{terms}}. Какое число следующее?', '1.0.0-draft'),
    ('G3-NUM-034', 'ru-KZ', 'plaintext', 'Было предметов: {{a}}. Куплено упаковок: {{b}}; предметов в каждой упаковке: {{c}}. Отдано предметов: {{d}}. Сколько предметов осталось?', '1.0.0-draft'),
    ('G3-NUM-035', 'ru-KZ', 'plaintext', 'Если {{a}} × {{b}} = {{product}}, чему равно {{b}} × {{a}}?', '1.0.0-draft'),
    ('G3-NUM-036', 'ru-KZ', 'plaintext', 'Вычислите: ({{a}} × {{b}}) × {{c}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
