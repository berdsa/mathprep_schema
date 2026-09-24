INSERT INTO task_type_template (type_id, locale, render_target, template_text, spec_version)
VALUES
 ('G10-ALG-001','ru-KZ','latex','Найдите вертикальную асимптоту функции $f(x)=\frac{3}{x-{{b}}}$.','1.0.0-draft'),
 ('G10-ALG-003','ru-KZ','latex','Для $f(x)=x^2+3x+{{a}}$ найдите остаток от деления многочлена на $x-2$.','1.0.0-draft'),
 ('G10-ALG-004','ru-KZ','latex','Является ли $x-{{a}}$ множителем многочлена $f(x)=x^2-{{a}}^2$? Ответьте true или false.','1.0.0-draft'),
 ('G10-ALG-005','ru-KZ','latex','Укажите возможные целые рациональные корни многочлена ${{a}}x^2+{{a}}$.','1.0.0-draft'),
 ('G10-ALG-007','ru-KZ','latex','Решите уравнение $\sqrt{{{a}}x+{{b}}}={{c}}$.','1.0.0-draft'),
 ('G10-ALG-008','ru-KZ','latex','В прямой пропорциональности $y=kx$ известно, что при $x={{b}}$ значение $y$ равно ${{a}}$. Найдите коэффициент $k$.','1.0.0-draft'),
 ('G10-ALG-009','ru-KZ','latex','В обратной пропорциональности $y=\frac{k}{x}$ известно, что при $x={{b}}$ значение $y$ равно ${{a}}$. Найдите коэффициент $k$.','1.0.0-draft'),
 ('G10-ALG-010','ru-KZ','latex','Верно ли равенство $1+2+\dots+n=\frac{n(n+1)}{2}$ при $n={{n}}$? Ответьте true или false.','1.0.0-draft'),
 ('G10-CAL-001','ru-KZ','latex','Вычислите предел: $\lim_{x\to{{a}}}({{p}}x\ {{q_sign}}\ {{q}})$.','1.0.0-draft'),
 ('G10-FUN-001','ru-KZ','latex','Пусть $f(x)={{a}}x+{{b}}$ и $g(x)={{b}}x+{{a}}$. Найдите значение композиции $(f\circ g)({{x}})$.','1.0.0-draft'),
 ('G10-FUN-002','ru-KZ','latex','Найдите обратную функцию $f^{-1}(x)$, если $f(x)={{a}}x+{{b}}$.','1.0.0-draft'),
 ('G10-FUN-003','ru-KZ','latex','Сдвигает ли график функции $f(x-{{h}})+{{k}}$ график вверх? Ответьте true или false.','1.0.0-draft'),
 ('G10-TRG-001','ru-KZ','latex','Решите уравнение $\sin(x)={{a}}$ на отрезке $x\in[0;2\pi)$. Ответ запишите в виде множителей $m$ числа $\pi/12$.','1.0.0-draft'),
 ('G11-ALG-001','ru-KZ','latex','Дана система $A\binom{x}{y}=\binom{{{e}}}{{{f}}}$, где $A=\begin{pmatrix}{{a}}&{{b}}\\{{c}}&{{d}}\end{pmatrix}$. Найдите $(x;y)$.','1.0.0-draft'),
 ('G11-FUN-001','ru-KZ','latex','Решите уравнение ${{a}}^x={{b}}$.','1.0.0-draft')
ON CONFLICT (type_id, locale, render_target, spec_version)
DO UPDATE SET template_text=EXCLUDED.template_text;
