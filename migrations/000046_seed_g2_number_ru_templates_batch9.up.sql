INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-NUM-041', 'ru-KZ', 'plaintext', 'Верно ли равенство {{a}} + {{b}} = {{c}}? Ответьте TRUE или FALSE.', '1.0.0-draft'),
    ('G2-NUM-042', 'ru-KZ', 'plaintext', 'Число {{n}} — чётное или нечётное? Введите один из кодов: even или odd.', '1.0.0-draft'),
    ('G2-NUM-043', 'ru-KZ', 'plaintext', 'Какие числа в списке [{{a}}, {{b}}, {{c}}, {{d}}] являются чётными? Введите список в исходном порядке.', '1.0.0-draft'),
    ('G2-NUM-044', 'ru-KZ', 'plaintext', 'Групп: {{a}}. В каждой группе: {{b}}. {{b}} + … + {{b}} = ?', '1.0.0-draft'),
    ('G2-NUM-045', 'ru-KZ', 'plaintext', 'Массив содержит {{r}} рядов и {{c}} столбцов. Сколько в нём объектов?', '1.0.0-draft'),
    ('G2-NUM-046', 'ru-KZ', 'plaintext', 'Групп: {{a}}. Всего предметов: {{p}}. Сколько предметов в каждой группе?', '1.0.0-draft'),
    ('G2-NUM-047', 'ru-KZ', 'plaintext', 'Если {{a}} + {{b}} = {{sum}}, чему равно {{sum}} − {{b}}?', '1.0.0-draft'),
    ('G2-NUM-048', 'ru-KZ', 'plaintext', 'Если {{a}} + {{b}} = {{sum}}, чему равно {{b}} + {{a}}?', '1.0.0-draft'),
    ('G2-NUM-049', 'ru-KZ', 'plaintext', 'Если {{a}} + {{b}} = {{sum}}, чему равно {{sum}} − {{a}}?', '1.0.0-draft'),
    ('G2-NUM-050', 'ru-KZ', 'plaintext', 'Количество предметов сначала неизвестно. Добавили: {{a}}. Стало: {{c}}. Сколько было сначала?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
