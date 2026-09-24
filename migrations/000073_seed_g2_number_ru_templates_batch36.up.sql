INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-NUM-001', 'ru-KZ', 'plaintext', 'Вычислите {{a}} + {{b}}.', '1.0.0-draft'),
    ('G2-NUM-002', 'ru-KZ', 'plaintext', 'Какое число непосредственно предшествует числу {{n}}?', '1.0.0-draft'),
    ('G2-NUM-003', 'ru-KZ', 'plaintext', 'В числе {{n}} укажите цифру в разряде десятков.', '1.0.0-draft'),
    ('G2-NUM-004', 'ru-KZ', 'plaintext', 'В числе {{n}} укажите цифру в разряде единиц.', '1.0.0-draft'),
    ('G2-NUM-005', 'ru-KZ', 'plaintext', 'Количество яблок сначала: {{a}}. Затем {{operation}} {{b}}. Сколько яблок стало?', '1.0.0-draft'),
    ('G2-NUM-006', 'ru-KZ', 'plaintext', 'В числе {{n}} найдите цифру в разряде {{place}}.', '1.0.0-draft'),
    ('G2-NUM-007', 'ru-KZ', 'plaintext', 'В числе {{n}} найдите значение цифры в разряде десятков.', '1.0.0-draft'),
    ('G2-NUM-008', 'ru-KZ', 'plaintext', 'В числе {{n}} найдите значение цифры в разряде единиц.', '1.0.0-draft'),
    ('G2-NUM-009', 'ru-KZ', 'plaintext', 'Продолжите последовательность {{start}}, {{next}}, ... Найдите число после {{count}} повторений правила: к текущему числу прибавить {{step}}.', '1.0.0-draft'),
    ('G2-MEA-008', 'ru-KZ', 'plaintext', 'Количество монет номиналом {{x}}: {{a}}; количество монет номиналом {{y}}: {{b}}. Найдите общую сумму.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
