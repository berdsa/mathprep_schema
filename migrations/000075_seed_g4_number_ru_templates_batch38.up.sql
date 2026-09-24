INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G4-NUM-019', 'ru-KZ', 'plaintext', 'Вычислите {{a}} + {{b}} × {{c}} − {{d}}.', '1.0.0-draft'),
    ('G4-NUM-020', 'ru-KZ', 'plaintext', 'Ответьте true или false: верно ли равенство {{a}} × {{b}} = {{c}} × {{d}}?', '1.0.0-draft'),
    ('G4-NUM-021', 'ru-KZ', 'plaintext', 'Сравните выражения {{a}} × {{b}} и {{c}} + {{d}}. Впишите знак <, > или =.', '1.0.0-draft'),
    ('G4-NUM-022', 'ru-KZ', 'plaintext', 'Какой знак нужно поставить вместо вопросительного знака: {{a}} ? {{b}} = {{c}}? Выберите +, −, × или ÷.', '1.0.0-draft'),
    ('G4-NUM-023', 'ru-KZ', 'plaintext', 'В числе {{n}} найдите цифру в разряде {{place}}.', '1.0.0-draft'),
    ('G4-NUM-024', 'ru-KZ', 'plaintext', 'Округлите число {{n}} до ближайшего значения, кратного {{p}}.', '1.0.0-draft'),
    ('G4-NUM-025', 'ru-KZ', 'plaintext', 'Вычислите {{a}} + {{b}}.', '1.0.0-draft'),
    ('G4-NUM-026', 'ru-KZ', 'plaintext', 'Вычислите {{a}} − {{b}}.', '1.0.0-draft'),
    ('G4-NUM-027', 'ru-KZ', 'plaintext', 'Вычислите {{a}} × {{b}}.', '1.0.0-draft'),
    ('G4-NUM-028', 'ru-KZ', 'plaintext', 'Вычислите {{a}} × {{b}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
