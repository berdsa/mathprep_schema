INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-MEA-009', 'ru-KZ', 'plaintext', 'Длина одной доски: {{a}} см. Длина другой доски: {{b}} см. Какова общая длина?', '1.0.0-draft'),
    ('G2-MEA-010', 'ru-KZ', 'plaintext', 'Длина верёвки: {{a}} см. Отрезали: {{b}} см. Сколько сантиметров осталось?', '1.0.0-draft'),
    ('G2-MEA-011', 'ru-KZ', 'plaintext', 'Сравните {{a}} см и {{b}} см: <, > или =.', '1.0.0-draft'),
    ('G2-MEA-012', 'ru-KZ', 'plaintext', 'Расположите {{a}} см, {{b}} см и {{c}} см от меньшей длины к большей.', '1.0.0-draft'),
    ('G2-MEA-013', 'ru-KZ', 'plaintext', 'Длина трёх отрезков: {{a}} см, {{b}} см, {{c}} см. Какова общая длина?', '1.0.0-draft'),
    ('G2-MEA-014', 'ru-KZ', 'plaintext', 'Сейчас {{h}}:00. Который час будет через {{k}} мин.? Используйте формат H:MM.', '1.0.0-draft'),
    ('G2-MEA-015', 'ru-KZ', 'plaintext', 'Сейчас {{h}}:{{m}}. Который час был {{k}} мин. назад? Используйте формат H:MM.', '1.0.0-draft'),
    ('G2-MEA-016', 'ru-KZ', 'plaintext', 'Начало: {{h}}:{{m1}}. Конец: {{h}}:{{m2}}. Сколько минут прошло?', '1.0.0-draft'),
    ('G2-MEA-017', 'ru-KZ', 'plaintext', 'Сейчас {{h}}:00 утра. Это AM или PM? Введите AM или PM.', '1.0.0-draft'),
    ('G2-STA-001', 'ru-KZ', 'plaintext', 'Количество животных: кошек — {{a}}, собак — {{b}}, птиц — {{c}}. Сколько всего животных?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
