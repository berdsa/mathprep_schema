INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G4-NUM-029', 'ru-KZ', 'plaintext', 'Найдите частное и остаток при делении {{a}} на {{b}}.', '1.0.0-draft'),
    ('G4-NUM-030', 'ru-KZ', 'plaintext', 'Оцените произведение {{a}} × {{b}}, предварительно округлив каждый множитель до ближайшего десятка.', '1.0.0-draft'),
    ('G4-NUM-031', 'ru-KZ', 'plaintext', 'Приближённо вычислите {{a}} ÷ {{b}}, округлив частное до ближайшего целого.', '1.0.0-draft'),
    ('G4-NUM-032', 'ru-KZ', 'plaintext', 'Сравните числа {{a}} и {{b}}. Впишите знак <, > или =.', '1.0.0-draft'),
    ('G4-NUM-033', 'ru-KZ', 'plaintext', 'Расположите значения по возрастанию: {{values}}.', '1.0.0-draft'),
    ('G4-NUM-034', 'ru-KZ', 'plaintext', 'Представьте число {{n}} в виде суммы разрядных слагаемых.', '1.0.0-draft'),
    ('G4-NUM-035', 'ru-KZ', 'plaintext', 'Вычислите сумму {{terms}}.', '1.0.0-draft'),
    ('G4-NUM-036', 'ru-KZ', 'plaintext', 'Запишите число словами «{{words}}» цифрами.', '1.0.0-draft'),
    ('G4-GEO-006', 'ru-KZ', 'plaintext', 'Сколько осей симметрии у {{shape}}?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
