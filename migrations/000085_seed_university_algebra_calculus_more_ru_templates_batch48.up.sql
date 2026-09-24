INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('U-ALG-004', 'ru-KZ', 'plaintext', 'Образует ли Z_{{modulus}} группу по сложению по модулю {{modulus}}? Ответьте true или false.', '1.0.0-draft'),
    ('U-ALG-005', 'ru-KZ', 'plaintext', 'Является ли Z_{{modulus}} с операциями сложения и умножения по модулю {{modulus}} кольцом? Ответьте true или false.', '1.0.0-draft'),
    ('U-ALG-006', 'ru-KZ', 'plaintext', 'Является ли Z_{{modulus}} с операциями по модулю {{modulus}} полем? Ответьте true или false.', '1.0.0-draft'),
    ('U-ALG-007', 'ru-KZ', 'plaintext', 'Является ли отображение φ: Z_{{modulus}} → Z_{{modulus}}, заданное формулой φ(x) = {{multiplier}}x mod {{modulus}}, гомоморфизмом колец? Ответьте true или false.', '1.0.0-draft'),
    ('U-ALG-008', 'ru-KZ', 'plaintext', 'Разложите 1/((x − {{a}})(x − {{b}})) в виде A/(x − {{a}}) + B/(x − {{b}}). Запишите сначала A, затем B.', '1.0.0-draft'),
    ('U-CAL-008', 'ru-KZ', 'plaintext', 'Для f(x,y) = x² + y² в точке P = ({{x}}; {{y}}) найдите производную по направлению единичного вектора ({{ux}}; {{uy}}).', '1.0.0-draft'),
    ('U-CAL-009', 'ru-KZ', 'plaintext', 'Вычислите тройной интеграл от {{k}} по области 0 ≤ x ≤ {{a}}, 0 ≤ y ≤ {{b}}, 0 ≤ z ≤ {{d}}.', '1.0.0-draft'),
    ('U-CAL-010', 'ru-KZ', 'plaintext', 'Для векторного поля F = ({{p}}; {{q}}) найдите ∫ F·dr вдоль отрезка от (0; 0) до ({{dx}}; {{dy}}).', '1.0.0-draft'),
    ('U-CAL-011', 'ru-KZ', 'plaintext', 'Для F = (0; 0; {{k}}) найдите поток вверх через прямоугольник 0 ≤ x ≤ {{a}}, 0 ≤ y ≤ {{b}}.', '1.0.0-draft'),
    ('U-CAL-012', 'ru-KZ', 'plaintext', 'Примените теорему Грина к P = 0, Q = {{k}}x на прямоугольнике 0 ≤ x ≤ {{a}}, 0 ≤ y ≤ {{b}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
