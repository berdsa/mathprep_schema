INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-NUM-051', 'ru-KZ', 'plaintext', 'Количество красных предметов: {{a}}. Синих: {{b}}. Сколько ещё предметов нужно, чтобы всего стало {{c}}?', '1.0.0-draft'),
    ('G2-NUM-052', 'ru-KZ', 'plaintext', 'Представьте число {{n}} в виде (сотни, десятки, единицы).', '1.0.0-draft'),
    ('G2-NUM-053', 'ru-KZ', 'plaintext', 'Какая цифра стоит в разряде {{place}} числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-054', 'ru-KZ', 'plaintext', 'Каково значение цифры десятков в числе {{n}}?', '1.0.0-draft'),
    ('G2-NUM-055', 'ru-KZ', 'plaintext', 'Запишите число {{n}} в развёрнутом виде, включая слагаемые с нулём.', '1.0.0-draft'),
    ('G2-NUM-056', 'ru-KZ', 'plaintext', 'Какое число равно {{h}}00 + {{t}}0 + {{o}}?', '1.0.0-draft'),
    ('G2-NUM-057', 'ru-KZ', 'plaintext', 'Сравните {{a}} и {{b}}: <, > или =.', '1.0.0-draft'),
    ('G2-NUM-058', 'ru-KZ', 'plaintext', 'Расположите числа {{a}}, {{b}}, {{c}} от меньшего к большему.', '1.0.0-draft'),
    ('G2-NUM-059', 'ru-KZ', 'plaintext', 'Какое число на 10 больше числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-060', 'ru-KZ', 'plaintext', 'Какое число на 10 меньше числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-061', 'ru-KZ', 'plaintext', 'Заполните пропуск: {{n}}, ?, {{end}}.', '1.0.0-draft'),
    ('G2-NUM-062', 'ru-KZ', 'plaintext', 'Сравните {{a}} + {{b}} и {{c}} − {{d}}: <, > или =.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
