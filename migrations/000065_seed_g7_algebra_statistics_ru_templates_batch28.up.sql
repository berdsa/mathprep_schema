INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G7-ALG-001', 'ru-KZ', 'plaintext', 'Упростите выражение: {{a}}(x + {{b}}) − {{c}}(x + {{d}}).', '1.0.0-draft'),
    ('G7-ALG-002', 'ru-KZ', 'plaintext', 'Решите систему уравнений: {{a1}}x + {{b1}}y = {{c1}}; {{a2}}x + {{b2}}y = {{c2}}. Запишите пару значений x,y через запятую.', '1.0.0-draft'),
    ('G7-ALG-004', 'ru-KZ', 'plaintext', 'Упростите сумму: ({{a}}x + {{b}}) + ({{c}}x + {{d}}).', '1.0.0-draft'),
    ('G7-ALG-005', 'ru-KZ', 'plaintext', 'Решите неравенство {{a}}x + {{b}} ≤ {{c}}. Запишите множество решений в виде промежутка (-∞, k].', '1.0.0-draft'),
    ('G7-FRA-005', 'ru-KZ', 'plaintext', 'Запишите дробь {{a}}/{{b}} в виде десятичной дроби, указав четыре знака после запятой.', '1.0.0-draft'),
    ('G7-STA-008', 'ru-KZ', 'plaintext', 'Медиана группы A равна {{a}}, группы B — {{b}}. В какой группе медиана больше? Ответьте кодом A или B.', '1.0.0-draft'),
    ('G7-STA-009', 'ru-KZ', 'plaintext', 'У прямой угловой коэффициент {{slope}}. Если x увеличить на 1, увеличится ли y? Ответьте true или false.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
