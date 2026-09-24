INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G8-ALG-006', 'ru-KZ', 'plaintext', 'Билет для взрослого стоит {{adult}} условных денежных единиц, для ребёнка — {{child}}. Продано {{total}} билетов на общую сумму {{revenue}}. Сколько билетов каждого вида продано? Запишите ответ как (взрослые, дети).', '1.0.0-draft'),
    ('G8-ALG-007', 'ru-KZ', 'plaintext', 'Решите неравенство {{a}}x + {{b}} < {{c}}x + {{d}}.', '1.0.0-draft'),
    ('G8-ALG-008', 'ru-KZ', 'plaintext', 'Упростите выражение ({{a}}^{{m}})^{{n}} × {{a}}^{{p}}.', '1.0.0-draft'),
    ('G8-ALG-009', 'ru-KZ', 'plaintext', 'Решите уравнение √x = {{a}}.', '1.0.0-draft'),
    ('G8-FUN-002', 'ru-KZ', 'plaintext', 'Прямая задана уравнением y = {{a}}x + ({{b}}). Найдите её угловой коэффициент.', '1.0.0-draft'),
    ('G8-FUN-003', 'ru-KZ', 'plaintext', 'График проходит через точки (0, {{b}}) и (1, {{m_plus_b}}). Запишите его уравнение в виде y = mx + b.', '1.0.0-draft'),
    ('G8-GEO-004', 'ru-KZ', 'plaintext', 'Удовлетворяют ли длины сторон {{a}}, {{b}} и {{c}} обратной теореме Пифагора? Ответьте true или false.', '1.0.0-draft'),
    ('G8-GEO-005', 'ru-KZ', 'plaintext', 'Перенесите точку ({{x}}, {{y}}) на вектор ({{dx}}, {{dy}}). Укажите новые координаты.', '1.0.0-draft'),
    ('G8-GEO-006', 'ru-KZ', 'plaintext', 'Отразите точку ({{x}}, {{y}}) относительно оси x. Укажите новые координаты.', '1.0.0-draft'),
    ('G8-GEO-007', 'ru-KZ', 'plaintext', 'Поверните точку ({{x}}, {{y}}) на 90° против часовой стрелки вокруг начала координат. Укажите новые координаты.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
