INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G6-ALG-008', 'ru-KZ', 'plaintext', 'Проверьте, является ли x = {{x}} решением уравнения {{b}}x + {{a}} = {{d}}.', '1.0.0-draft'),
    ('G6-ALG-009', 'ru-KZ', 'plaintext', 'В уравнении y = kx какая переменная является зависимой?', '1.0.0-draft'),
    ('G6-ALG-010', 'ru-KZ', 'plaintext', 'Если x удвоить в уравнении y = kx, что произойдёт с y?', '1.0.0-draft'),
    ('G6-DEC-001', 'ru-KZ', 'plaintext', 'Сколько составляет {{percentage}}% от {{number}}?', '1.0.0-draft'),
    ('G6-DEC-002', 'ru-KZ', 'plaintext', 'Измените число {{number}} на {{percentage}}%: {{direction}}.', '1.0.0-draft'),
    ('G6-DEC-003', 'ru-KZ', 'plaintext', 'Сколько составляет {{p}}% от {{n}} учеников?', '1.0.0-draft'),
    ('G6-DEC-004', 'ru-KZ', 'plaintext', 'Представьте дробь {{a}}/100 в виде процента.', '1.0.0-draft'),
    ('G6-DEC-005', 'ru-KZ', 'plaintext', 'Вычислите: {{left}} + {{right}}.', '1.0.0-draft'),
    ('G6-DEC-006', 'ru-KZ', 'plaintext', 'Вычислите: {{left}} {{operator}} {{right}}.', '1.0.0-draft'),
    ('G6-DEC-007', 'ru-KZ', 'plaintext', 'Вычислите произведение: {{left}} × {{right}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
