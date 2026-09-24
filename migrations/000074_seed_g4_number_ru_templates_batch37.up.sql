INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G4-NUM-007', 'ru-KZ', 'plaintext', 'Представьте число {{n}} в виде суммы разрядных слагаемых.', '1.0.0-draft'),
    ('G4-NUM-008', 'ru-KZ', 'plaintext', 'Вычислите {{a}} × {{b}}.', '1.0.0-draft'),
    ('G4-NUM-009', 'ru-KZ', 'plaintext', 'Вычислите {{a}} ÷ {{b}}.', '1.0.0-draft'),
    ('G4-NUM-010', 'ru-KZ', 'plaintext', 'Найдите частное и остаток при делении {{a}} на {{b}}.', '1.0.0-draft'),
    ('G4-NUM-011', 'ru-KZ', 'plaintext', 'Начальная сумма: {{a}}. Покупка: {{b}} единиц по {{c}} за каждую единицу. После оплаты {{d}} найдите остаток.', '1.0.0-draft'),
    ('G4-NUM-012', 'ru-KZ', 'plaintext', 'Запишите число {{n}} римскими цифрами.', '1.0.0-draft'),
    ('G4-NUM-013', 'ru-KZ', 'plaintext', 'Перечислите все пары положительных целых множителей числа {{n}}.', '1.0.0-draft'),
    ('G4-NUM-014', 'ru-KZ', 'plaintext', 'Определите вид числа {{n}}. Ответьте токеном prime (простое) или composite (составное).', '1.0.0-draft'),
    ('G4-NUM-015', 'ru-KZ', 'plaintext', 'Запишите значения {{n}} × 1, {{n}} × 2, …, {{n}} × {{k}}.', '1.0.0-draft'),
    ('G4-NUM-016', 'ru-KZ', 'plaintext', 'Продолжите геометрическую последовательность {{terms}}. Отношение соседних членов постоянно.', '1.0.0-draft'),
    ('G4-NUM-017', 'ru-KZ', 'plaintext', 'Найдите результат умножения {{k}} на {{n}}.', '1.0.0-draft'),
    ('G4-NUM-018', 'ru-KZ', 'plaintext', 'Если значение {{b}} взять {{k}} раз, какой результат получится?', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
