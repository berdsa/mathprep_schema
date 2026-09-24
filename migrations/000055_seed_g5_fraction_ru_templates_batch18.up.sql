INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G5-FRA-001', 'ru-KZ', 'plaintext', 'Первая дробь: {{a}}/{{b}}. Вторая дробь: {{c}}/{{d}}. Найдите сумму дробей.', '1.0.0-draft'),
    ('G5-FRA-002', 'ru-KZ', 'plaintext', 'Первая дробь: {{a}}/{{b}}. Вторая дробь: {{c}}/{{d}}. Найдите разность первой и второй дробей.', '1.0.0-draft'),
    ('G5-FRA-003', 'ru-KZ', 'plaintext', 'Вычислите сумму дробей: {{a}}/{{b}} + {{c}}/{{d}}.', '1.0.0-draft'),
    ('G5-FRA-004', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} + {{c}}/{{d}}.', '1.0.0-draft'),
    ('G5-FRA-005', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} − {{c}}/{{d}}.', '1.0.0-draft'),
    ('G5-FRA-006', 'ru-KZ', 'plaintext', 'Вычислите: {{w1}} {{a}}/{{b}} + {{w2}} {{c}}/{{d}}.', '1.0.0-draft'),
    ('G5-FRA-007', 'ru-KZ', 'plaintext', 'Вычислите: {{w1}} {{a}}/{{b}} − {{w2}} {{c}}/{{d}}.', '1.0.0-draft'),
    ('G5-FRA-008', 'ru-KZ', 'plaintext', 'Первая величина: {{a}}/{{b}}. Вторая величина: {{c}}/{{d}}. Найдите их сумму.', '1.0.0-draft'),
    ('G5-FRA-009', 'ru-KZ', 'plaintext', 'Вычислите произведение дробей: {{a}}/{{b}} × {{c}}/{{d}}.', '1.0.0-draft'),
    ('G5-FRA-010', 'ru-KZ', 'plaintext', 'Вычислите произведение смешанных чисел: {{w1}} {{a}}/{{b}} × {{w2}} {{c}}/{{d}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
