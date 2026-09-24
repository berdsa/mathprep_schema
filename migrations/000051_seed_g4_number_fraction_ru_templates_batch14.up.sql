INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G4-NUM-005', 'ru-KZ', 'plaintext', 'Начальное количество: {{a}}. Изменение количества: {{operation}} {{b}}. Найдите итоговое количество.', '1.0.0-draft'),
    ('G4-NUM-006', 'ru-KZ', 'plaintext', 'Расположите числа {{a}}, {{b}} и {{c}} от меньшего к большему.', '1.0.0-draft'),
    ('G4-FRA-001', 'ru-KZ', 'plaintext', 'В равенстве {{a}}/{{b}} = ?/{{c}} найдите число вместо вопросительного знака.', '1.0.0-draft'),
    ('G4-FRA-002', 'ru-KZ', 'plaintext', 'Сравните дроби {{a}}/{{b}} и {{c}}/{{d}}: <, > или =.', '1.0.0-draft'),
    ('G4-FRA-003', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{d}} + {{b}}/{{d}}.', '1.0.0-draft'),
    ('G4-FRA-004', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{d}} − {{b}}/{{d}}.', '1.0.0-draft'),
    ('G4-FRA-005', 'ru-KZ', 'plaintext', 'Вычислите: {{w1}} {{a}}/{{d}} + {{w2}} {{b}}/{{d}}.', '1.0.0-draft'),
    ('G4-FRA-006', 'ru-KZ', 'plaintext', 'Вычислите: {{w1}} {{a}}/{{d}} − {{w2}} {{b}}/{{d}}.', '1.0.0-draft'),
    ('G4-FRA-007', 'ru-KZ', 'plaintext', 'Вычислите: {{a}}/{{b}} × {{n}}.', '1.0.0-draft'),
    ('G4-FRA-008', 'ru-KZ', 'plaintext', '{{n}} одинаковых групп содержат по {{a}}/{{b}}. Сколько составляет общее количество?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
