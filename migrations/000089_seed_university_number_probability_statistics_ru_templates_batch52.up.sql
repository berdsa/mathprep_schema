INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
    ('U-NUM-001', 'ru-KZ', 'plaintext', 'Для f(x) = x² − {{c}} выполните один шаг метода Ньютона, начиная с x₀ = {{x0}}.', '1.0.0-draft'),
    ('U-PRO-001', 'ru-KZ', 'plaintext', 'Для равномерной случайной величины X на множестве {1, …, {{n}}} найдите её {{operation}}.', '1.0.0-draft'),
    ('U-PRO-002', 'ru-KZ', 'plaintext', 'Выборка имеет среднее {{mean}}, стандартное отклонение {{sd}} и объём n = {{n}}. Найдите 95%-й доверительный интервал для генерального среднего.', '1.0.0-draft'),
    ('U-PRO-003', 'ru-KZ', 'plaintext', 'Дано P(X и Y) = {{joint}} и P(Y) = {{given}}. Найдите P(X|Y).', '1.0.0-draft'),
    ('U-PRO-004', 'ru-KZ', 'plaintext', 'По формуле Байеса: P(H) = {{prior}}%, P(E|H) = {{lh}}%, P(E|не H) = {{lnot}}%. Найдите P(H|E).', '1.0.0-draft'),
    ('U-STA-001', 'ru-KZ', 'plaintext', 'Для X ~ Binomial(n = {{n}}, p = {{p}}) найдите P(X = {{k}}).', '1.0.0-draft'),
    ('U-STA-002', 'ru-KZ', 'plaintext', 'Для X ~ Normal(μ = {{mu}}, σ = {{sigma}}) найдите P({{a}} < X < {{b}}).', '1.0.0-draft'),
    ('U-STA-003', 'ru-KZ', 'plaintext', 'В совместной таблице частота клетки равна {{cell}} при общем числе наблюдений {{total}}. Найдите совместную вероятность.', '1.0.0-draft'),
    ('U-STA-004', 'ru-KZ', 'plaintext', 'При увеличении объёма выборки n = {{n}} до бесконечности сходится ли выборочное среднее к генеральному среднему? Ответьте true или false.', '1.0.0-draft'),
    ('U-STA-005', 'ru-KZ', 'plaintext', 'Для достаточно большой выборки объёма n = {{n}} утверждает ли центральная предельная теорема, что распределение выборочного среднего приблизительно нормально? Ответьте true или false.', '1.0.0-draft'),
    ('U-STA-006', 'ru-KZ', 'plaintext', 'Найдите наклон прямой наименьших квадратов, проходящей через точки ({{x1}}, {{y1}}) и ({{x2}}, {{y2}}).', '1.0.0-draft'),
    ('U-STA-007', 'ru-KZ', 'plaintext', 'Для групп A = {{groupA}} и B = {{groupB}} найдите F-статистику однофакторного дисперсионного анализа.', '1.0.0-draft'),
    ('U-STA-008', 'ru-KZ', 'plaintext', 'Найдите 95%-й доверительный интервал для μ при x̄ = {{mean}}, известном σ = {{sigma}} и n = {{n}}.', '1.0.0-draft'),
    ('U-STA-009', 'ru-KZ', 'plaintext', 'Найдите двустороннее p-значение для статистики z-теста z = {{z}}.', '1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text = EXCLUDED.template_text;
