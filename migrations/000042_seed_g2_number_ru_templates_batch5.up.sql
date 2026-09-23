INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-NUM-011', 'ru-KZ', 'plaintext', 'Какое число стоит перед {{n}}?', '1.0.0-draft'),
    ('G2-NUM-012', 'ru-KZ', 'plaintext', 'Какая цифра стоит в разряде десятков числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-013', 'ru-KZ', 'plaintext', 'Какая цифра стоит в разряде единиц числа {{n}}?', '1.0.0-draft'),
    ('G2-NUM-014', 'ru-KZ', 'plaintext', 'Запишите число {{n}} как упорядоченную пару (число десятков, цифра единиц).', '1.0.0-draft'),
    ('G2-NUM-015', 'ru-KZ', 'plaintext', 'Каково значение цифры десятков в числе {{n}}?', '1.0.0-draft'),
    ('G2-NUM-016', 'ru-KZ', 'plaintext', 'Каково значение цифры единиц в числе {{n}}?', '1.0.0-draft'),
    ('G2-NUM-017', 'ru-KZ', 'plaintext', 'Сравните {{a}} и {{b}}: <, > или =.', '1.0.0-draft'),
    ('G2-NUM-018', 'ru-KZ', 'plaintext', 'Расположите числа {{a}}, {{b}}, {{c}} от меньшего к большему.', '1.0.0-draft'),
    ('G2-NUM-019', 'ru-KZ', 'plaintext', '{{a}} + {{b}} = ?', '1.0.0-draft'),
    ('G2-NUM-020', 'ru-KZ', 'plaintext', '{{a}} − {{b}} = ?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
