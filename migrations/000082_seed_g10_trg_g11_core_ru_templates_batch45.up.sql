INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G10-TRG-001', 'ru-KZ', 'plaintext', 'Решите уравнение sin(x) = {{a}} на отрезке x ∈ [0; 2π). Ответ запишите в виде множителей m числа π/12.', '1.0.0-draft'),
    ('G11-ALG-001', 'ru-KZ', 'plaintext', 'Дана система A·(x; y)ᵀ = ({{e}}; {{f}})ᵀ, где A = [[{{a}}, {{b}}]; [{{c}}, {{d}}]]. Найдите (x; y).', '1.0.0-draft'),
    ('G11-FUN-001', 'ru-KZ', 'plaintext', 'Решите уравнение {{a}}^x = {{b}}.', '1.0.0-draft'),
    ('G11-LOG-001', 'ru-KZ', 'plaintext', 'Решите уравнение log_{{b}}(x) = {{c}}.', '1.0.0-draft'),
    ('G11-MAT-001', 'ru-KZ', 'plaintext', 'Для матриц A = [[{{a}}, {{b}}]; [{{c}}, {{d}}]] и B = [[{{e}}, {{f}}]; [{{g}}, {{h}}]] найдите {{operation}}.', '1.0.0-draft'),
    ('G11-MAT-002', 'ru-KZ', 'plaintext', 'Найдите det([[{{a}}, {{b}}]; [{{c}}, {{d}}]]).', '1.0.0-draft'),
    ('G11-NUM-001', 'ru-KZ', 'plaintext', 'Выполните операцию: ({{a}}{{b}}i) {{operation}} ({{c}}{{d}}i). Ответ запишите как пару (действительная часть, мнимая часть).', '1.0.0-draft'),
    ('G11-PRO-001', 'ru-KZ', 'plaintext', 'P(A∩B) = {{j}}/{{n}}, P(B) = {{b}}/{{n}}. Найдите P(A|B).', '1.0.0-draft'),
    ('G11-STA-001', 'ru-KZ', 'plaintext', 'Для X ~ N({{mu}}, {{sigma}}²) найдите P(X < {{x}}).', '1.0.0-draft'),
    ('G11-STA-002', 'ru-KZ', 'plaintext', 'Найдите z-оценку для x = {{x}} при μ = {{mu}} и σ = {{sigma}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
