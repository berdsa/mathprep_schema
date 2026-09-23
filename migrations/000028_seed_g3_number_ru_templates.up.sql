INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-NUM-016', 'ru-KZ', 'plaintext', 'Найдите делитель: {{a}} ÷ ? = {{c}}.', '1.0.0-draft'),
    ('G3-NUM-017', 'ru-KZ', 'plaintext', 'Заполните пропуск: ? ÷ {{b}} = {{c}}.', '1.0.0-draft'),
    ('G3-NUM-018', 'ru-KZ', 'plaintext', 'Сложите {{groups}} одинаковых слагаемых, каждое равно {{each}}. Какова сумма?', '1.0.0-draft'),
    ('G3-NUM-019', 'ru-KZ', 'plaintext', 'Всего предметов: {{n}}. Их поровну распределили между {{groups}} группами. Сколько предметов в каждой группе?', '1.0.0-draft'),
    ('G3-NUM-020', 'ru-KZ', 'plaintext', 'Количество сумок: {{bags}}. Количество яблок в одной сумке: {{each}}. Сколько яблок всего?', '1.0.0-draft'),
    ('G3-NUM-021', 'ru-KZ', 'plaintext', 'Количество предметов: {{n}}. Их поровну распределили между {{groups}} группами. Сколько предметов приходится на одну группу?', '1.0.0-draft'),
    ('G3-NUM-022', 'ru-KZ', 'plaintext', 'Вычислите сумму: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G3-NUM-023', 'ru-KZ', 'plaintext', 'Вычислите разность: {{a}} − {{b}}.', '1.0.0-draft'),
    ('G3-NUM-024', 'ru-KZ', 'plaintext', 'Вычислите сумму: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G3-NUM-025', 'ru-KZ', 'plaintext', 'Вычислите разность: {{a}} − {{b}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
