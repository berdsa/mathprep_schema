INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('U-ALG-001', 'ru-KZ', 'plaintext', 'Сколько существует {{n}}-х корней из единицы? Ответьте числом.', '1.0.0-draft'),
    ('U-ALG-002', 'ru-KZ', 'plaintext', 'Переведите полярные координаты (r = {{r}}, θ = {{theta}}°) в декартовы координаты (x; y).', '1.0.0-draft'),
    ('U-ALG-003', 'ru-KZ', 'plaintext', 'Исключите параметр t из соотношений {{relation}}. Выразите y через x.', '1.0.0-draft'),
    ('U-CAL-001', 'ru-KZ', 'plaintext', 'Вычислите предел: lim(x → {{a}}) [{{m}}(x − {{a}})]/[{{n}}(x − {{a}})].', '1.0.0-draft'),
    ('U-CAL-004', 'ru-KZ', 'plaintext', 'Для функции f(x,y) = {{a}}x + {{b}}y + {{c}} в точке ({{x0}}; {{y0}}) найдите {{operation}} в направлении {{direction}}.', '1.0.0-draft'),
    ('U-CAL-006', 'ru-KZ', 'plaintext', 'Вычислите определённый интеграл ∫ от {{l}} до {{u}} ({{a}}x + {{b}}) dx.', '1.0.0-draft'),
    ('U-CAL-007', 'ru-KZ', 'plaintext', 'Вычислите двойной интеграл постоянной {{c}} по прямоугольнику {{x1}} ≤ x ≤ {{x2}}, {{y1}} ≤ y ≤ {{y2}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
