INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G7-ALG-016', 'ru-KZ', 'plaintext', '{{a}}(x + ({{b}})) − {{c}} = {{rhs}}. Найдите x.', '1.0.0-draft'),
    ('G7-ALG-017', 'ru-KZ', 'plaintext', '{{a}}x + {{b}} = {{c}}x + {{d}}. Найдите x.', '1.0.0-draft'),
    ('G7-ALG-018', 'ru-KZ', 'plaintext', 'Выразите y через x из уравнения {{a}}x + {{b}}y = {{c}}.', '1.0.0-draft'),
    ('G7-ALG-019', 'ru-KZ', 'plaintext', 'Решите неравенство {{a}}x + {{b}} ≤ {{c}}. Запишите ответ в форме x ≤ k.', '1.0.0-draft'),
    ('G7-ALG-020', 'ru-KZ', 'plaintext', 'Для прямой y = {{a}}x + ({{b}}) укажите упорядоченную пару (угловой коэффициент, ордината точки пересечения с осью y).', '1.0.0-draft'),
    ('G7-ALG-021', 'ru-KZ', 'plaintext', 'Запишите уравнение прямой с угловым коэффициентом {{m}}, проходящей через точку ({{x}}, {{y}}), в виде y − ({{y}}) = {{m}}(x − ({{x}})).', '1.0.0-draft'),
    ('G7-ALG-022', 'ru-KZ', 'plaintext', 'Найдите угловой коэффициент прямой, перпендикулярной прямой y = {{a}}x + 4.', '1.0.0-draft'),
    ('G7-ALG-023', 'ru-KZ', 'plaintext', 'Найдите точку пересечения прямых y = {{m1}}x + 2 и y = {{m2}}x + 2.', '1.0.0-draft'),
    ('G7-ALG-024', 'ru-KZ', 'plaintext', 'Решите систему: y = {{a}}x + {{c}}; {{b}}x + {{d}}y = {{e}}.', '1.0.0-draft'),
    ('G7-ALG-025', 'ru-KZ', 'plaintext', 'Решите систему: {{a}}x + {{b}}y = {{e}}; {{c}}x + {{d}}y = {{f}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
