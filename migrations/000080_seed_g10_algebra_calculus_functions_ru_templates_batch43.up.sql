INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G10-ALG-001', 'ru-KZ', 'plaintext', 'Найдите вертикальную асимптоту функции f(x) = 3/(x − {{b}}).', '1.0.0-draft'),
    ('G10-ALG-003', 'ru-KZ', 'plaintext', 'Для f(x) = x² + 3x + {{a}} найдите остаток от деления многочлена на x − 2.', '1.0.0-draft'),
    ('G10-ALG-004', 'ru-KZ', 'plaintext', 'Является ли x − {{a}} множителем многочлена f(x) = x² − {{a}}²? Ответьте true или false.', '1.0.0-draft'),
    ('G10-ALG-005', 'ru-KZ', 'plaintext', 'Укажите возможные целые рациональные корни многочлена {{a}}x² + {{a}}.', '1.0.0-draft'),
    ('G10-ALG-007', 'ru-KZ', 'plaintext', 'Решите уравнение √({{a}}x + {{b}}) = {{c}}.', '1.0.0-draft'),
    ('G10-ALG-008', 'ru-KZ', 'plaintext', 'В прямой пропорциональности y = kx известно, что при x = {{b}} значение y равно {{a}}. Найдите коэффициент k.', '1.0.0-draft'),
    ('G10-ALG-009', 'ru-KZ', 'plaintext', 'В обратной пропорциональности y = k/x известно, что при x = {{b}} значение y равно {{a}}. Найдите коэффициент k.', '1.0.0-draft'),
    ('G10-ALG-010', 'ru-KZ', 'plaintext', 'Верно ли равенство 1 + 2 + … + n = n(n + 1)/2 при n = {{n}}? Ответьте true или false.', '1.0.0-draft'),
    ('G10-CAL-001', 'ru-KZ', 'plaintext', 'Вычислите предел: lim(x → {{a}}) ({{p}}x {{q_sign}} {{q}}).', '1.0.0-draft'),
    ('G10-FUN-001', 'ru-KZ', 'plaintext', 'Пусть f(x) = {{a}}x + {{b}} и g(x) = {{b}}x + {{a}}. Найдите значение композиции (f∘g)({{x}}).', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
