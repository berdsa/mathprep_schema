INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('U-CAL-023', 'ru-KZ', 'plaintext', 'Является ли функция {{function}} аналитической на всей комплексной плоскости? Ответьте true или false.', '1.0.0-draft'),
    ('U-CAL-024', 'ru-KZ', 'plaintext', 'Является ли функция {{function}} равномерно непрерывной на вещественной прямой? Ответьте true или false.', '1.0.0-draft'),
    ('U-CAL-025', 'ru-KZ', 'plaintext', 'Интегрируема ли по Риману на [−1; 1] ступенчатая функция {{function}}? Ответьте true или false.', '1.0.0-draft'),
    ('U-DIS-001', 'ru-KZ', 'plaintext', 'Граф имеет вершины 0..{{vertices}} и рёбра {{{{edges}}}}. Найдите {{query}}.', '1.0.0-draft'),
    ('U-DIS-002', 'ru-KZ', 'plaintext', 'Вычислите остаток от деления {{a}}^{{exponent}} на {{modulus}}.', '1.0.0-draft'),
    ('U-DIS-003', 'ru-KZ', 'plaintext', 'Пусть A = {{{{A}}}} и B = {{{{B}}}}. Найдите мощность их {{operation}}.', '1.0.0-draft'),
    ('U-DIS-004', 'ru-KZ', 'plaintext', 'Сколькими способами можно выбрать {{k}} объектов из {{n}}?', '1.0.0-draft'),
    ('U-DIS-005', 'ru-KZ', 'plaintext', 'Сколько рёбер имеет дерево с {{n}} вершинами?', '1.0.0-draft'),
    ('U-DIS-006', 'ru-KZ', 'plaintext', 'Решите систему сравнений x ≡ {{a}} (mod {{m}}), x ≡ {{b}} (mod {{n}}), где 0 ≤ x < {{limit}}.', '1.0.0-draft'),
    ('U-DIS-007', 'ru-KZ', 'plaintext', 'По теореме Эйлера найдите {{a}}^φ({{n}}) по модулю {{n}}.', '1.0.0-draft'),
    ('U-DIS-008', 'ru-KZ', 'plaintext', 'Даны логические значения P = {{p}} и Q = {{q}}. Найдите значение P ∧ Q.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
