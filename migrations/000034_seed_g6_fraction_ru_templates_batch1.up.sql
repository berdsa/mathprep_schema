INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G6-FRA-001', 'ru-KZ', 'plaintext', '{{a}}/{{b}} = {{c}}/x. Найдите x.', '1.0.0-draft'),
    ('G6-FRA-002', 'ru-KZ', 'plaintext', 'Вычислите: 1/{{b}} ÷ {{n}}.', '1.0.0-draft'),
    ('G6-FRA-003', 'ru-KZ', 'plaintext', 'Вычислите: {{n}} ÷ (1/{{b}}).', '1.0.0-draft'),
    ('G6-FRA-004', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} {{operator}} {{c}}/{{d}}.', '1.0.0-draft'),
    ('G6-FRA-005', 'ru-KZ', 'plaintext', 'Заполните пропуск в отношении: {{a}}:{{b}} = ?:{{d}}.', '1.0.0-draft'),
    ('G6-FRA-006', 'ru-KZ', 'plaintext', 'Количество одинаковых товаров: {{a}}. Их общая стоимость: {{b}}. Найдите стоимость одного товара.', '1.0.0-draft'),
    ('G6-FRA-007', 'ru-KZ', 'plaintext', 'Количество единиц товара: {{a}}. Общая стоимость: {{b}}. Найдите цену одной единицы.', '1.0.0-draft'),
    ('G6-FRA-008', 'ru-KZ', 'plaintext', 'Отношение частей: {{a}}:{{b}}. Сумма частей: {{t}}. Найдите большую часть.', '1.0.0-draft'),
    ('G6-FRA-009', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} ÷ {{c}}/{{d}}.', '1.0.0-draft'),
    ('G6-FRA-010', 'ru-KZ', 'plaintext', 'Сравните дроби {{a}}/{{b}} и {{c}}/{{d}}. Укажите знак: <, > или =.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
