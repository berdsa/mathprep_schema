UPDATE task_type
SET widget_config = jsonb_build_object(
    'choices', ARRAY[
        '<', 'less', 'less than',
        '>', 'greater', 'greater than',
        '=', 'equal', 'equal to',
        'true', 'false',
        'red', 'blue', 'green', 'cats', 'dogs', 'birds',
        'cm', 'kg', 'l', '2d', '3d',
        'square', 'triangle', 'pentagon', 'hexagon', 'octagon',
        'odd', 'even', 'am', 'pm', 'prime', 'composite',
        '+', '-', '×', '÷',
        'i', 'ii', 'iii', 'iv', 'ox', 'oy', 'o'
    ]::TEXT[]
)
WHERE validation_method = 'BOOL';
