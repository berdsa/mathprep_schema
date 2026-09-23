INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-NUM-021', 'ru-KZ', 'plaintext', 'Какое число на 10 больше числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-022', 'ru-KZ', 'plaintext', 'Какое число на 10 меньше числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-023', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + {{b}}.', '1.0.0-draft'),
    ('G2-NUM-024', 'ru-KZ', 'plaintext', 'Последовательность: {{terms}}, ... Каждый раз прибавляйте 10. Какое число следующее?', '1.0.0-draft'),
    ('G2-NUM-025', 'ru-KZ', 'plaintext', 'Последовательность: {{terms}}, ... Каждый раз прибавляйте 5. Какое число следующее?', '1.0.0-draft'),
    ('G2-NUM-026', 'ru-KZ', 'plaintext', 'Последовательность: {{terms}}, ... Каждый раз прибавляйте 2. Какое число следующее?', '1.0.0-draft'),
    ('G2-NUM-027', 'ru-KZ', 'plaintext', 'Какое число содержит {{t}} десятков и {{o}} единиц?', '1.0.0-draft'),
    ('G2-NUM-028', 'ru-KZ', 'plaintext', 'Вычислите: {{t}}0 + {{o}}.', '1.0.0-draft'),
    ('G2-NUM-029', 'ru-KZ', 'plaintext', 'Заполните пропуск: {{terms}}.', '1.0.0-draft'),
    ('G2-NUM-030', 'ru-KZ', 'plaintext', 'Какое число больше: {{a}} или {{b}}?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
