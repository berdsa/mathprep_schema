INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-GEO-025', 'ru-KZ', 'plaintext', 'Фигура разделена на 4 равные части. Какую дробь составляет одна часть?', '1.0.0-draft'),
    ('G2-GEO-026', 'ru-KZ', 'plaintext', 'Фигура разделена на {{d}} равные части. Закрашена 1 часть. Какая дробь закрашена?', '1.0.0-draft'),
    ('G2-GEO-027', 'ru-KZ', 'plaintext', 'Прямоугольник разделён на 4 равные части. Закрашена 1 часть. Сколько частей не закрашено?', '1.0.0-draft'),
    ('G2-GEO-028', 'ru-KZ', 'plaintext', 'У какой фигуры больше сторон: у пятиугольника или шестиугольника?', '1.0.0-draft'),
    ('G2-GEO-029', 'ru-KZ', 'plaintext', 'У фигуры 8 сторон. Как она называется?', '1.0.0-draft'),
    ('G2-GEO-030', 'ru-KZ', 'plaintext', 'Верно ли, что квадрат является прямоугольником? Ответьте TRUE или FALSE.', '1.0.0-draft'),
    ('G2-GEO-031', 'ru-KZ', 'plaintext', 'В прямоугольнике {{r}} рядов и {{t}} единичных квадратов. Сколько в нём столбцов?', '1.0.0-draft'),
    ('G4-NUM-001', 'ru-KZ', 'plaintext', 'Сложите числа {{a}} и {{b}}.', '1.0.0-draft'),
    ('G4-NUM-002', 'ru-KZ', 'plaintext', 'Представьте число {{n}} как количество тысяч, сотен, десятков и единиц.', '1.0.0-draft'),
    ('G4-NUM-003', 'ru-KZ', 'plaintext', 'Сравните числа {{a}} и {{b}}: <, > или =.', '1.0.0-draft'),
    ('G4-NUM-004', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} {{op}} {{b}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
