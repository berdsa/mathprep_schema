INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G1-NUM-011', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G1-NUM-012', 'ru-KZ', 'plaintext', '{{a}} − ? = {{c}}. Найдите пропущенное число.', '1.0.0-draft'),
    ('G1-NUM-013', 'ru-KZ', 'plaintext', '? − {{b}} = {{c}}. Найдите пропущенное число.', '1.0.0-draft'),
    ('G1-NUM-014', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}} + {{c}}.', '1.0.0-draft'),
    ('G1-NUM-015', 'ru-KZ', 'plaintext', 'Сравните {{a}} + {{b}} и {{c}}: <, > или =.', '1.0.0-draft'),
    ('G1-NUM-016', 'ru-KZ', 'plaintext', 'Количество яблок было равно {{a}}. Добавили ещё {{b}}. Сколько яблок стало?', '1.0.0-draft'),
    ('G1-NUM-017', 'ru-KZ', 'plaintext', 'Количество яблок сначала: {{a}}. Потом: {{c}}. Сколько яблок добавили?', '1.0.0-draft'),
    ('G1-NUM-018', 'ru-KZ', 'plaintext', 'Количество яблок после добавления {{b}} равно {{c}}. Сколько яблок было сначала?', '1.0.0-draft'),
    ('G1-NUM-019', 'ru-KZ', 'plaintext', 'Количество яблок было равно {{a}}. Убрали {{b}}. Сколько яблок осталось?', '1.0.0-draft'),
    ('G1-NUM-020', 'ru-KZ', 'plaintext', 'Количество яблок было равно {{a}}. Затем осталось {{c}}. Сколько яблок убрали?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
