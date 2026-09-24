INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G5-NUM-001', 'ru-KZ', 'plaintext', 'Найдите {{operation}} чисел {{a}} и {{b}}.', '1.0.0-draft'),
    ('G5-NUM-002', 'ru-KZ', 'plaintext', 'Делится ли число {{n}} на {{d}} без остатка? Ответьте YES или NO.', '1.0.0-draft'),
    ('G5-NUM-003', 'ru-KZ', 'plaintext', 'Вычислите: ({{a}} + {{b}}) × {{c}} − {{d}}.', '1.0.0-draft'),
    ('G5-NUM-004', 'ru-KZ', 'plaintext', 'Вычислите: [({{a}} + {{b}}) × {{c}}] − {{d}}.', '1.0.0-draft'),
    ('G5-NUM-005', 'ru-KZ', 'plaintext', 'Запишите выражение для величины на {{a}} больше произведения {{b}} на {{c}}.', '1.0.0-draft'),
    ('G5-NUM-006', 'ru-KZ', 'plaintext', 'Выберите смысл выражения {{n}} × ({{b}} + {{c}}). Ответ задаётся стандартной английской фразой.', '1.0.0-draft'),
    ('G5-NUM-007', 'ru-KZ', 'plaintext', 'Вычислите: {{a}} + ({{b}} × {{c}}) − {{d}}.', '1.0.0-draft'),
    ('G5-NUM-008', 'ru-KZ', 'plaintext', 'Последовательность: {{sequence}}, … Сначала прибавляют {{d1}}, затем {{d2}}, чередуя эти шаги. Найдите следующий член.', '1.0.0-draft'),
    ('G5-NUM-009', 'ru-KZ', 'plaintext', 'Начальное количество: {{a}}. Потратили: {{b}}. Получили: {{c}}. Затем потратили: {{d}}. Сколько осталось?', '1.0.0-draft'),
    ('G5-NUM-010', 'ru-KZ', 'plaintext', 'Представьте сумму {{a}} + {{b}} в виде {{g}}({{c}} + {{d}}), вынеся общий множитель — наибольший общий делитель.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
