INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G1-MEA-005', 'ru-KZ', 'plaintext', 'Сейчас {{h}}:00. Какое время будет через {{k}} ч? Введите ответ в минутах.', '1.0.0-draft'),
    ('G1-MEA-006', 'ru-KZ', 'plaintext', 'Сейчас {{h}}:00. Который час будет через 30 минут? Используйте формат Ч:ММ.', '1.0.0-draft'),
    ('G1-MEA-007', 'ru-KZ', 'plaintext', 'Сейчас {{h}}:30. Который час был 30 минут назад? Используйте формат Ч:ММ.', '1.0.0-draft'),
    ('G1-STA-001', 'ru-KZ', 'plaintext', 'Количество предметов: красных — {{a}}, синих — {{b}}, зелёных — {{c}}. Сколько всего?', '1.0.0-draft'),
    ('G1-STA-002', 'ru-KZ', 'plaintext', 'Количество предметов: красных — {{a}}, синих — {{b}}. На сколько красных больше?', '1.0.0-draft'),
    ('G1-STA-003', 'ru-KZ', 'plaintext', 'Количество предметов: красных — {{a}}, синих — {{b}}, зелёных — {{c}}. Какого цвета предметов больше всего? Введите один из кодов: red, blue или green.', '1.0.0-draft'),
    ('G1-MEA-008', 'ru-KZ', 'plaintext', 'Какая единица измеряет длину: cm, kg или L?', '1.0.0-draft'),
    ('G1-MEA-009', 'ru-KZ', 'plaintext', 'Верно ли, что {{a}} см длиннее {{b}} см? Ответьте TRUE или FALSE.', '1.0.0-draft'),
    ('G1-MEA-010', 'ru-KZ', 'plaintext', 'Длина A: {{a}} см. Длина B: {{b}} см. На сколько A длиннее B?', '1.0.0-draft'),
    ('G1-STA-004', 'ru-KZ', 'plaintext', 'Количество животных: кошек — {{a}}, собак — {{b}}. Сколько всего животных?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
