INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G8-ALG-010', 'ru-KZ', 'plaintext', 'Решите уравнение |{{a}}x + ({{b}})| = {{c}}.', '1.0.0-draft'),
    ('G8-ALG-011', 'ru-KZ', 'plaintext', 'Решите неравенство |{{a}}x + ({{b}})| < {{c}}.', '1.0.0-draft'),
    ('G8-ALG-012', 'ru-KZ', 'plaintext', 'Вынесите общий множитель {{gcf}} за скобки: {{gcf}}·({{x}}) + {{gcf}}·({{y}}).', '1.0.0-draft'),
    ('G8-ALG-013', 'ru-KZ', 'plaintext', 'Разложите x² − {{b}}² на множители, используя разность квадратов.', '1.0.0-draft'),
    ('G8-ALG-015', 'ru-KZ', 'plaintext', 'Решите уравнение {{a}}(x − {{h}})² = {{k}}.', '1.0.0-draft'),
    ('G8-ALG-016', 'ru-KZ', 'plaintext', 'Решите квадратное уравнение x² + ({{b}})x + ({{c}}) = 0.', '1.0.0-draft'),
    ('G8-ALG-017', 'ru-KZ', 'plaintext', 'Решите квадратное уравнение x² + ({{b}})x + ({{c}}) = 0, выделив полный квадрат.', '1.0.0-draft'),
    ('G8-ALG-018', 'ru-KZ', 'plaintext', 'Найдите координаты вершины параболы y = {{a}}(x − {{h}})² + {{k}}.', '1.0.0-draft'),
    ('G8-ALG-019', 'ru-KZ', 'plaintext', 'Упростите выражение ({{a}}^{{m}})^{{n}} × {{a}}^{{p}}.', '1.0.0-draft'),
    ('G8-ALG-021', 'ru-KZ', 'plaintext', 'Упростите дробь (x² − {{a}}²)/(x − {{a}}), учитывая ограничение x ≠ {{a}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
