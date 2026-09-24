INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('U-CAL-026', 'ru-KZ', 'plaintext', 'Является ли {{metric}} метрикой на множестве вещественных чисел? Ответьте true или false.', '1.0.0-draft'),
    ('U-FUN-001', 'ru-KZ', 'plaintext', 'Сходится ли геометрический ряд со знаменателем {{ratio}}? Ответьте YES или NO.', '1.0.0-draft'),
    ('U-FUN-002', 'ru-KZ', 'plaintext', 'Найдите сумму сходящегося геометрического ряда с первым членом a = {{a}} и знаменателем r = {{ratio}}.', '1.0.0-draft'),
    ('U-MAT-001', 'ru-KZ', 'plaintext', 'Найдите ранг матрицы [[{{a}}, {{b}}]; [{{c}}, {{d}}]].', '1.0.0-draft'),
    ('U-MAT-002', 'ru-KZ', 'plaintext', 'Найдите собственные значения матрицы [[{{lambda1}}, 0]; [0, {{lambda2}}]].', '1.0.0-draft'),
    ('U-MAT-003', 'ru-KZ', 'plaintext', 'Найдите обратную матрицу к [[{{a}}, 0]; [0, {{b}}]].', '1.0.0-draft'),
    ('U-MAT-004', 'ru-KZ', 'plaintext', 'Решите диагональную систему {{d1}}x₁ = {{r1}}, {{d2}}x₂ = {{r2}}, {{d3}}x₃ = {{r3}}.', '1.0.0-draft'),
    ('U-MAT-005', 'ru-KZ', 'plaintext', 'Найдите размерность линейной оболочки векторов ({{a}}; {{b}}) и ({{c}}; {{d}}).', '1.0.0-draft'),
    ('U-MAT-006', 'ru-KZ', 'plaintext', 'Ортогональны ли векторы u = ({{ux}}; {{uy}}) и v = ({{vx}}; {{vy}})? Ответьте true или false.', '1.0.0-draft'),
    ('U-MAT-007', 'ru-KZ', 'plaintext', 'Найдите сингулярные числа диагональной матрицы [[{{a}}, 0]; [0, {{b}}]].', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
