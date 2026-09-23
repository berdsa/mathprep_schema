INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('G2-GEO-011', 'ru-KZ', 'plaintext', 'Сколько сторон у фигуры «{{shape}}»?', '1.0.0-draft'),
    ('G2-GEO-012', 'ru-KZ', 'plaintext', 'Сколько вершин у фигуры «{{shape}}»?', '1.0.0-draft'),
    ('G2-GEO-013', 'ru-KZ', 'plaintext', 'У какой фигуры число сторон равно {{sides}}? Введите один из кодов: triangle, square, pentagon или hexagon.', '1.0.0-draft'),
    ('G2-GEO-014', 'ru-KZ', 'plaintext', 'Тело: «{{solid}}». Считая все плоские и криволинейные граничные поверхности, сколько у него граней?', '1.0.0-draft'),
    ('G2-GEO-015', 'ru-KZ', 'plaintext', 'Сколько рёбер у куба?', '1.0.0-draft'),
    ('G2-GEO-016', 'ru-KZ', 'plaintext', 'Сколько вершин у куба?', '1.0.0-draft'),
    ('G2-GEO-017', 'ru-KZ', 'plaintext', 'Тело: «{{solid}}». Сколько у него рёбер?', '1.0.0-draft'),
    ('G2-GEO-018', 'ru-KZ', 'plaintext', 'Тело: «{{solid}}». Сколько у него вершин?', '1.0.0-draft'),
    ('G2-GEO-019', 'ru-KZ', 'plaintext', 'У какой фигуры число сторон равно {{n}}? Введите один из кодов: triangle, square, pentagon, hexagon или octagon.', '1.0.0-draft'),
    ('G2-GEO-020', 'ru-KZ', 'plaintext', 'Фигура «{{shape}}» является четырёхугольником? Ответьте TRUE или FALSE.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
