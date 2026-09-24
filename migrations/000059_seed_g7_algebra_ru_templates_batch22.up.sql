INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G7-ALG-006', 'ru-KZ', 'plaintext', '{{a}}^{{m}} × {{a}}^{{n}} = ?', '1.0.0-draft'),
    ('G7-ALG-007', 'ru-KZ', 'plaintext', 'Разложите выражение {{a}}x + {{a}}y на множители.', '1.0.0-draft'),
    ('G7-ALG-008', 'ru-KZ', 'plaintext', '{{a}}(x + {{b}}) = {{c}}. Найдите x.', '1.0.0-draft'),
    ('G7-ALG-009', 'ru-KZ', 'plaintext', 'Число умножили на {{a}}, затем прибавили {{b}} и получили {{c}}. Найдите это число.', '1.0.0-draft'),
    ('G7-ALG-010', 'ru-KZ', 'plaintext', 'Решите неравенство {{a}}x + {{b}} ≥ {{c}}. Укажите все значения x, при которых выражение не меньше {{c}}.', '1.0.0-draft'),
    ('G7-ALG-011', 'ru-KZ', 'plaintext', 'Решите неравенство x > {{a}} и запишите ответ в виде промежутка.', '1.0.0-draft'),
    ('G7-ALG-012', 'ru-KZ', 'plaintext', '{{a}}x + {{b}} = {{c}}x + {{d}}. Найдите x.', '1.0.0-draft'),
    ('G7-ALG-013', 'ru-KZ', 'plaintext', '{{a}}x + {{b}} = {{a}}x + {{c}}. Имеет ли уравнение решение?', '1.0.0-draft'),
    ('G7-ALG-014', 'ru-KZ', 'plaintext', '{{a}}(x + {{b}}) = {{a}}x + {{a_times_b}}. Верно ли равенство при любом x?', '1.0.0-draft'),
    ('G7-ALG-015', 'ru-KZ', 'plaintext', '({{a}}/{{b}})x + {{c}} = {{d}}. Найдите x.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
