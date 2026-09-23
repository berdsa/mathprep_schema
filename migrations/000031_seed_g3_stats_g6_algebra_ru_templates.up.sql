INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G3-NUM-047', 'ru-KZ', 'plaintext', 'Разложите числа по разрядам и найдите сумму: {{a}} + {{b}} + {{c}}.', '1.0.0-draft'),
    ('G3-STA-001', 'ru-KZ', 'plaintext', 'На столбчатой диаграмме для категории «Яблоки» указано значение {{c}}. Запишите это значение.', '1.0.0-draft'),
    ('G3-STA-002', 'ru-KZ', 'plaintext', 'На столбчатой диаграмме указаны значения: яблоки — {{a}}, бананы — {{b}}, вишни — {{c}}. Найдите сумму.', '1.0.0-draft'),
    ('G3-STA-003', 'ru-KZ', 'plaintext', 'На диаграмме указаны значения: яблоки — {{a}}, бананы — {{b}}. На сколько значение для яблок больше?', '1.0.0-draft'),
    ('G3-STA-004', 'ru-KZ', 'plaintext', 'На пиктограмме один символ означает {{v}}. Показано символов: {{k}}. Найдите общее значение.', '1.0.0-draft'),
    ('G6-ALG-001', 'ru-KZ', 'plaintext', 'Решите уравнение: {{a}}x + {{b}} = {{c}}.', '1.0.0-draft'),
    ('G6-ALG-002', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}^{{b}} + {{c}}.', '1.0.0-draft'),
    ('G6-ALG-003', 'ru-KZ', 'plaintext', 'Запишите выражение: из {{b}}x вычтите {{a}}.', '1.0.0-draft'),
    ('G6-ALG-004', 'ru-KZ', 'plaintext', 'Равносильны ли выражения {{a}}(x + {{b}}) и {{a}}x + ({{a}} × {{b}})?', '1.0.0-draft'),
    ('G6-ALG-005', 'ru-KZ', 'plaintext', 'Упростите выражение: {{a}}(x + {{b}}) + {{c}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
