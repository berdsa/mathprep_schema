INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G8-NUM-001', 'ru-KZ', 'plaintext', 'Является ли число √{{n}} рациональным? Ответьте true или false.', '1.0.0-draft'),
    ('G8-NUM-002', 'ru-KZ', 'plaintext', 'Приближённо вычислите √{{n}} с точностью до сотых.', '1.0.0-draft'),
    ('G8-NUM-003', 'ru-KZ', 'plaintext', 'Вычислите √{{n}}.', '1.0.0-draft'),
    ('G8-NUM-004', 'ru-KZ', 'plaintext', 'Вычислите ∛{{n}}.', '1.0.0-draft'),
    ('G8-NUM-005', 'ru-KZ', 'plaintext', 'Упростите выражение {{a}}^(−{{n}}). Запишите ответ в виде точной дроби.', '1.0.0-draft'),
    ('G8-GEO-003', 'ru-KZ', 'plaintext', 'Параллельны ли прямые с угловыми коэффициентами {{m1}} и {{m2}}? Ответьте true или false.', '1.0.0-draft'),
    ('G8-NUM-006', 'ru-KZ', 'plaintext', 'Представьте произведение {{a}}^{{m}} × {{a}}^{{n}} одной степенью с основанием {{a}}.', '1.0.0-draft'),
    ('G8-NUM-007', 'ru-KZ', 'plaintext', 'Запишите число {{coefficient}} 000 000 в виде произведения коэффициента на степень числа 10.', '1.0.0-draft'),
    ('G8-NUM-008', 'ru-KZ', 'plaintext', 'Вычислите ({{a}} × 10^{{m}}) × ({{b}} × 10^{{n}}). Запишите результат в форме c × 10^k.', '1.0.0-draft'),
    ('G8-ALG-005', 'ru-KZ', 'plaintext', 'Решите систему уравнений y = {{a}}x + {{b}} и y = {{d}}x + {{rhs}}. Запишите пару (x, y).', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
