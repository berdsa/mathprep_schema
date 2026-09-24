INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('U-CAL-013', 'ru-KZ', 'plaintext', 'Примените теорему Стокса для F = (−y/2; x/2; 0) на окружности радиуса {{r}}.', '1.0.0-draft'),
    ('U-CAL-014', 'ru-KZ', 'plaintext', 'Примените теорему о дивергенции для F = ({{k}}x; {{k}}y; {{k}}z) в области 0 ≤ x ≤ {{a}}, 0 ≤ y ≤ {{b}}, 0 ≤ z ≤ {{d}}.', '1.0.0-draft'),
    ('U-CAL-015', 'ru-KZ', 'plaintext', 'Найдите радиус сходимости степенного ряда {{series}}.', '1.0.0-draft'),
    ('U-CAL-016', 'ru-KZ', 'plaintext', 'По правилу {{rule}} найдите lim(x → 0) sin(x)/x.', '1.0.0-draft'),
    ('U-CAL-017', 'ru-KZ', 'plaintext', 'Для f(x) = x² − 2 на отрезке [{{a}}; {{b}}] выполните один шаг метода бисекции и найдите середину отрезка.', '1.0.0-draft'),
    ('U-CAL-018', 'ru-KZ', 'plaintext', 'Для f(x) = x² на отрезке [{{a}}; {{b}}] примените формулу трапеций при n = {{n}} и найдите приближённое значение.', '1.0.0-draft'),
    ('U-CAL-019', 'ru-KZ', 'plaintext', 'Используя точки (0;1), (1;3), (2;7), найдите значение интерполяционного многочлена Лагранжа при x = {{x}}.', '1.0.0-draft'),
    ('U-CAL-020', 'ru-KZ', 'plaintext', 'Вычислите ({{a}} + {{b}}i)/({{c}} + {{d}}i) и запишите действительную и мнимую части.', '1.0.0-draft'),
    ('U-CAL-021', 'ru-KZ', 'plaintext', 'Положительно ориентированная окружность охватывает один полюс с вычетом {{residue}}. Найдите контурный интеграл.', '1.0.0-draft'),
    ('U-CAL-022', 'ru-KZ', 'plaintext', 'Вычислите ∮C (1/z) dz, где C — положительно ориентированная окружность |z| = {{radius}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
