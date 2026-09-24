INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G7-ALG-026', 'ru-KZ', 'plaintext', 'Цена билета для взрослого — {{adult}} условных денежных единиц, для ребёнка — {{child}}. Куплено {{total}} билетов на общую сумму {{revenue}}. Сколько билетов каждого вида куплено? Запишите ответ как (взрослые, дети).', '1.0.0-draft'),
    ('G7-FUN-013', 'ru-KZ', 'plaintext', 'Функция задана формулой f(x) = {{a}}x + ({{b}}). Найдите f({{x}}).', '1.0.0-draft'),
    ('G7-STA-010', 'ru-KZ', 'plaintext', 'Найдите среднее арифметическое чисел: {{values}}.', '1.0.0-draft'),
    ('G7-STA-011', 'ru-KZ', 'plaintext', 'Найдите размах набора чисел: {{values}}.', '1.0.0-draft'),
    ('G7-GEO-012', 'ru-KZ', 'plaintext', 'Точка B лежит между точками A и C. Длины AB = {{a}} и BC = {{b}}. Найдите длину AC.', '1.0.0-draft'),
    ('G7-GEO-003', 'ru-KZ', 'plaintext', 'Два угла треугольника равны {{a}}° и {{b}}°. Найдите третий угол.', '1.0.0-draft'),
    ('G7-GEO-006', 'ru-KZ', 'plaintext', 'Какую форму имеет горизонтальное сечение цилиндра? Введите название фигуры по-английски, как в варианте ответа (circle).', '1.0.0-draft'),
    ('G7-GEO-007', 'ru-KZ', 'plaintext', 'Найдите дополнительный угол к углу величиной {{a}}°.', '1.0.0-draft'),
    ('G7-GEO-008', 'ru-KZ', 'plaintext', 'Найдите смежный угол к углу величиной {{a}}° (сумма смежных углов равна 180°).', '1.0.0-draft'),
    ('G7-GEO-009', 'ru-KZ', 'plaintext', 'Образовалась пара вертикальных углов. Один из них равен {{a}}°. Найдите второй.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
