INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-STA-002', 'ru-KZ', 'plaintext', 'Количество кошек: {{a}}. Собак: {{b}}. На сколько кошек больше?', '1.0.0-draft'),
    ('G2-STA-003', 'ru-KZ', 'plaintext', 'Количество животных: кошек — {{a}}, собак — {{b}}, птиц — {{c}}. Какая группа животных самая многочисленная? Введите один из кодов: cats, dogs или birds.', '1.0.0-draft'),
    ('G2-STA-004', 'ru-KZ', 'plaintext', 'Список данных: {{values}}. Сколько значений в списке?', '1.0.0-draft'),
    ('G2-STA-005', 'ru-KZ', 'plaintext', 'Список данных: {{values}}. Какова их сумма?', '1.0.0-draft'),
    ('G2-MEA-018', 'ru-KZ', 'plaintext', 'Какая единица измеряет массу? Введите один из кодов: cm, kg или L.', '1.0.0-draft'),
    ('G2-MEA-019', 'ru-KZ', 'plaintext', 'Верно ли, что {{a}} см длиннее {{b}} см? Ответьте TRUE или FALSE.', '1.0.0-draft'),
    ('G2-GEO-021', 'ru-KZ', 'plaintext', 'Прямоугольник разбит на одинаковые квадраты. Число рядов: {{r}}. Число столбцов: {{c}}. Сколько всего квадратов?', '1.0.0-draft'),
    ('G2-GEO-022', 'ru-KZ', 'plaintext', 'Фигура составлена из единичных квадратов. Число рядов: {{r}}. Число столбцов: {{c}}. Какова площадь фигуры в квадратных единицах?', '1.0.0-draft'),
    ('G2-GEO-023', 'ru-KZ', 'plaintext', 'Фигура разделена на 2 равные части. Какую дробь составляет одна часть?', '1.0.0-draft'),
    ('G2-GEO-024', 'ru-KZ', 'plaintext', 'Фигура разделена на 3 равные части. Какую дробь составляет одна часть?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
