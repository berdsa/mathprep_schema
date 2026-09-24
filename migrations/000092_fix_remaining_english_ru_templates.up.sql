INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
 ('G2-NUM-019','ru-KZ','plaintext','{{a}} + {{b}} = ?','1.0.0-draft'),
 ('G2-NUM-020','ru-KZ','plaintext','{{a}} − {{b}} = ?','1.0.0-draft'),
 ('G3-FRA-008','ru-KZ','plaintext','Какую часть, равную 1/{{b}}, составляет число {{n}}?','1.0.0-draft'),
 ('G3-NUM-002','ru-KZ','plaintext','Вычислите произведение: {{a}} × {{b}}.','1.0.0-draft'),
 ('G3-NUM-003','ru-KZ','plaintext','Выполните деление: {{a}} ÷ {{b}}.','1.0.0-draft'),
 ('G6-NUM-002','ru-KZ','plaintext','Вычислите: {{a}} {{operator}} {{b}}.','1.0.0-draft'),
 ('G7-ALG-006','ru-KZ','plaintext','Упростите выражение {{a}}^{{m}} × {{a}}^{{n}}.','1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text=EXCLUDED.template_text;
