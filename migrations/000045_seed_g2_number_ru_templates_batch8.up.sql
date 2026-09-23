INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-NUM-031', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G2-NUM-032', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} − {{b}}.', '1.0.0-draft'),
    ('G2-NUM-033', 'ru-KZ', 'plaintext', '{{a}} + ? = {{c}}. Найдите пропущенное число.', '1.0.0-draft'),
    ('G2-NUM-034', 'ru-KZ', 'plaintext', '{{a}} − ? = {{c}}. Найдите пропущенное число.', '1.0.0-draft'),
    ('G2-NUM-035', 'ru-KZ', 'plaintext', '? − {{b}} = {{c}}. Найдите пропущенное число.', '1.0.0-draft'),
    ('G2-NUM-036', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}} + {{c}}.', '1.0.0-draft'),
    ('G2-NUM-037', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}} + {{c}} + {{d}}.', '1.0.0-draft'),
    ('G2-NUM-038', 'ru-KZ', 'plaintext', 'Количество предметов сначала: {{a}}. Добавили: {{b}}. Убрали: {{c}}. Сколько предметов стало?', '1.0.0-draft'),
    ('G2-NUM-039', 'ru-KZ', 'plaintext', 'Коробок: {{a}}. В каждой коробке предметов: {{b}}. Отдельно предметов: {{c}}. Сколько всего предметов?', '1.0.0-draft'),
    ('G2-NUM-040', 'ru-KZ', 'plaintext', 'Сравните {{a}} + {{b}} и {{c}} − {{d}}: <, > или =.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
