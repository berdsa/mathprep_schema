# Math Task Type Catalog — Grade 1 to University

Design principle: each task type is parametrized (dynamic variables), generates a single templated problem string, and has a deterministically computable correct answer that can be automatically validated. Graph-plotting, geometric construction, and open-ended proof tasks are excluded since they cannot be auto-validated.

## Validation-method legend

| Code | Meaning |
|---|---|
| **EXACT-INT** | Exact integer/string match |
| **EXACT-RAT** | Exact match after reducing to lowest terms |
| **TOL** | Numeric match within a configured tolerance (decimals, irrational results) |
| **SET** | Unordered set/multiset match (e.g., two roots, factor list) |
| **CANON** | Canonical string form after normalization (interval notation, ratio, factorization) |
| **CAS** | Symbolic equivalence via a CAS (e.g., `simplify(given - correct) == 0`) |
| **BOOL** | Boolean or fixed-vocabulary label match |
| **TUPLE** | Ordered tuple/vector, component-wise (with TOL if needed) |
| **MATRIX** | Element-wise matrix comparison (with TOL if needed) |

---

## Grade 1–2 (ages 6–8)

| Task Type | Prompt Pattern | Dynamic Variables | Answer / Validation |
|---|---|---|---|
| Addition within range | `a + b = ?` | a, b, range | EXACT-INT |
| Subtraction within range | `a − b = ?` | a, b, range | EXACT-INT |
| Number comparison | `Compare a and b: <, >, =` | a, b | EXACT-INT (symbol enum) |
| Missing addend | `a + ? = c` | a, c | EXACT-INT |
| Simple word problem (add/sub) | "Had a, got b more / gave away b — how many now?" | a, b, item noun | EXACT-INT |
| Place value | `What digit is in the tens place of n?` | n, digit position | EXACT-INT |
| Ordering a list | `Order [list] from smallest to largest` | list of n values | CANON (sorted list) |
| Money counting | `a coins of X + b coins of Y = ?` | a, b, denominations | EXACT-INT |
| Skip counting / next term | `start, start+step, ... next?` | start, step, count | EXACT-INT |
| Shape property lookup | `How many sides/vertices does a [named shape] have?` | shape name (fixed set) | EXACT-INT |

## Grade 3–4 (ages 8–10)

| Task Type | Prompt Pattern | Dynamic Variables | Answer / Validation |
|---|---|---|---|
| Multiplication fact | `a × b = ?` | a, b | EXACT-INT |
| Exact division | `a ÷ b = ?` (b \| a) | a, b | EXACT-INT |
| Multi-digit add/sub (carry/borrow) | `a + b`, `a − b` | a, b (digit count) | EXACT-INT |
| Order of operations | `a + b × c − d ÷ e` | a..e (integer-result guaranteed) | EXACT-INT |
| Rounding | `Round n to the nearest [10/100]` | n, place | EXACT-INT |
| Unit fraction of a quantity | `What is 1/b of n?` (b \| n) | b, n | EXACT-INT |
| Perimeter of rectangle/square | `Sides a, b — perimeter?` | a, b | EXACT-INT |
| Area of rectangle/square | `Sides a, b — area?` | a, b | EXACT-INT |
| Division with remainder | `a ÷ b = ? remainder ?` | a, b | TUPLE (quotient, remainder) |
| Roman numeral conversion | `Convert n ↔ Roman numeral` | n (1–3999) | CANON (string) |
| Simple sequence pattern | `Find next term: arithmetic/geometric` | start, step/ratio, n | EXACT-INT |

## Grade 5–6 (ages 10–12)

| Task Type | Prompt Pattern | Dynamic Variables | Answer / Validation |
|---|---|---|---|
| Fraction add/subtract | `a/b ± c/d` | a,b,c,d | EXACT-RAT |
| Fraction multiply/divide | `a/b × or ÷ c/d` | a,b,c,d | EXACT-RAT |
| Decimal arithmetic | `a ± × ÷ b` (decimals) | a, b, decimal places | TOL |
| Percentage of a number | `What is p% of n?` | p, n | EXACT-RAT / TOL |
| Percentage change | `n increases/decreases by p% → ?` | n, p, direction | TOL |
| Ratio simplification | `Simplify a : b` | a, b | CANON (reduced ratio) |
| Proportion solving | `a/b = c/x, find x` | a,b,c | EXACT-RAT |
| GCD / LCM | `GCD or LCM of a, b` | a, b | EXACT-INT |
| Negative number arithmetic | `a ± × ÷ b` (signed) | a, b | EXACT-INT |
| Point quadrant identification | `Which quadrant is (x, y) in?` | x, y | BOOL (I–IV / axis) |
| Distance between two points | `Distance between (x1,y1),(x2,y2)` | coordinates | TOL / CAS (simplified radical) |
| Basic single-event probability | `P(rolling a on a die)`, cards, coins | scenario params | EXACT-RAT |
| Volume of rectangular prism/cube | `Dimensions a,b,c — volume?` | a,b,c | EXACT-INT |
| Missing triangle/polygon angle | `Given angles, find missing one` | n-1 known angles | EXACT-INT |
| Unit conversion | `Convert value from unit X to Y` | value, unit pair | TOL |

## Grade 7–9 (ages 12–15)

| Task Type | Prompt Pattern | Dynamic Variables | Answer / Validation |
|---|---|---|---|
| Linear equation (1 var) | `ax + b = c` | a,b,c (clean solution) | EXACT-RAT |
| Linear system (2 vars) | `a1x+b1y=c1; a2x+b2y=c2` | coefficients (integer solution) | TUPLE |
| Quadratic equation | `ax² + bx + c = 0` | roots chosen → a,b,c | SET (2 roots) |
| Quadratic inequality | `ax² + bx + c > 0` (etc.) | a,b,c | CANON (interval) |
| Linear inequality | `ax + b ≤ c` | a,b,c | CANON (interval) |
| Exponent rules | `Simplify aᵐ × aⁿ`, etc. | a, m, n | EXACT-INT / CAS |
| Radical simplification | `Simplify √n` | n | CAS (simplified radical form) |
| Polynomial expansion | `(ax+b)(cx+d)` | a,b,c,d | CAS |
| Polynomial factoring | `Factor x² + bx + c` | roots chosen → b,c | CAS |
| Pythagorean theorem | `Legs a,b — hypotenuse?` | a, b | TOL / EXACT-INT (Pythagorean triples) |
| Similar triangles ratio | `Scale factor k, side a — corresponding side?` | a, k | TOL |
| Circle metrics | `Circumference/area/arc/sector, r, θ` | r, θ | TOL (π symbolic or decimal) |
| Basic trig ratio (special angles) | `sin/cos/tan of 30°/45°/60°, find side` | angle, given side | TOL |
| Permutations & combinations | `nPr / nCr` | n, k | EXACT-INT |
| Compound probability | `P(A and B)`, `P(A or B)` | event params | EXACT-RAT |
| Mean/median/mode/range | `Dataset [list] → statistic` | generated dataset | EXACT-RAT / TOL |
| Function evaluation | `f(x) = ..., find f(a)` | coefficients, a | EXACT-RAT |
| Domain check | `Which x-values make f(x) defined?` | candidate list | SET |
| Prime factorization | `Factor n into primes` | n | CANON (sorted multiset) |
| Divisibility check | `Is n divisible by d?` | n, d | BOOL |

## Grade 10–11 (ages 15–18)

| Task Type | Prompt Pattern | Dynamic Variables | Answer / Validation |
|---|---|---|---|
| Trig equation on an interval | `sin(x) = k, x ∈ [0, 2π)` | k (special value), interval | SET (angles) |
| Logarithmic equation | `log_b(x) = c` or `log equation` | b, c | EXACT-RAT |
| Exponential equation | `a^x = b` | a, b (clean solution) | EXACT-RAT / CAS |
| Arithmetic sequence | `nth term / sum of n terms` | a1, d, n | EXACT-INT |
| Geometric sequence | `nth term / finite or infinite sum` | a1, r, n | EXACT-RAT / TOL |
| Basic limit | `lim(x→a) f(x)`, polynomial/rational | function params, a | EXACT-RAT / "∞"/"DNE" |
| Derivative (poly/trig/exp/log) | `f(x) = ... , find f'(x)` | function type + coefficients | CAS |
| Tangent line at a point | `Find tangent to f at x=a` | function, a | CAS |
| Extrema / monotonicity | `Find and classify critical points of f` | function params | TUPLE (point + label) |
| Binomial theorem term | `Find the kth term / coefficient of (x+y)ⁿ` | n, k | EXACT-INT |
| Conditional probability | `P(A\|B)` given joint/marginal data | scenario params | EXACT-RAT |
| Complex number arithmetic | `(a+bi) ± × ÷ (c+di)`, modulus/argument | a,b,c,d | TUPLE / TOL |
| Vector operations | `Dot product, magnitude, angle between u, v` | vector components | TOL |
| Matrix operations (2×2/3×3) | `Add/multiply/determinant of A, B` | matrix entries | MATRIX / EXACT-INT |
| Linear system via matrices | `Solve via Cramer's rule / inverse` | coefficient matrix | TUPLE |

## University (higher mathematics)

| Task Type | Prompt Pattern | Dynamic Variables | Answer / Validation |
|---|---|---|---|
| Limit with indeterminate form | `lim f(x)/g(x)` needing L'Hôpital | function params | EXACT-RAT / "∞" |
| Advanced derivative | Implicit / chain / product / quotient rule | function structure | CAS |
| Partial derivative | `∂f/∂x, ∂f/∂y` for f(x,y) | function of x,y | CAS |
| Gradient / directional derivative | `∇f at point P`, direction vector | function, point, direction | TUPLE (TOL) |
| Indefinite integral | `∫f(x)dx` | function params | CAS (mod constant) |
| Definite integral | `∫ₐᵇ f(x)dx` | function, a, b | TOL |
| Double integral (simple region) | `∬ f(x,y) dA` over rectangle/triangle | function, bounds | TOL |
| Series convergence test | `Does Σaₙ converge? Which test?` | series formula | BOOL / label |
| Sum of a convergent series | `Σ (infinite)` | series params | TOL |
| First-order ODE | `Solve y' = f(x,y)` (separable/linear) | ODE coefficients | CAS |
| Second-order linear ODE | Constant-coefficient, given initial conditions | coefficients, ICs | CAS |
| Matrix rank | `rank(A)` | matrix entries | EXACT-INT |
| Eigenvalues / eigenvectors | Small matrix, clean eigenvalues | matrix entries (constructed) | SET / TUPLE (TOL) |
| Matrix inverse | `A⁻¹` (det ≠ 0) | matrix entries | MATRIX (TOL) |
| Linear system (n variables) | Gaussian elimination | coefficient matrix, n | TUPLE |
| Expectation / variance of a distribution | Discrete or continuous RV, given params | distribution + params | TOL |
| Confidence interval / hypothesis stat | Sample mean, sd, n → CI or test statistic | sample stats | TOL |
| Graph theory (numeric) | Edge count, degree sequence, shortest path | adjacency data | EXACT-INT |
| Modular arithmetic / number theory | Modular exponentiation, CRT | a, n, mod | EXACT-INT |
| Set theory / logic | Truth table row, `\|A ∪ B\|`, `\|A ∩ B\|` | sets / propositions | EXACT-INT / BOOL |
| Complex analysis basics | Roots of unity, modulus/argument | n, complex value | SET (TOL) |
| Numerical method iteration | One Newton–Raphson / bisection step | f, x₀ | TOL |

---

## Notes for implementation (methodologist + BA perspective)

1. **Well-posedness first, like your quadratic generator.** For every type, constrain the random generation so the *intended* solution form holds — e.g., force clean roots for factoring, non-zero determinants for inverses, `|r|<1` for infinite geometric sums. Reject-and-retry loops (as in `QuadraticEquation`) are the right pattern; just also guard against infinite loops when constraints get tight (log a warning after N retries).
2. **Normalize before comparing, not after.** Reduce fractions, sort unordered answers (roots, factor lists, sets), round to a stated precision, and strip formatting — do this once in a shared `Validate()` layer rather than per task type, or CANON/SET rules will drift between generators.
3. **CAS-backed types need a sandboxed evaluator.** Everything marked CAS (derivatives, integrals, factoring, ODEs) should route through one evaluation service (e.g., SymPy) with a timeout and a fixed variable name convention (`x`, `y`) — don't hand-roll symbolic comparison per task.
4. **Localization stays in the template layer only.** Keep `Problem` as a template string with `{a}`, `{b}` placeholders per locale; numbers/answers stay locale-agnostic internally and are only formatted for display (decimal comma vs. point, thousands separators). This matches your existing `model.Response{Problem, Solution}` shape — just add a `Locale` key resolving to the template.
5. **Difficulty is a parameter range, not a new type.** Reuse the same generator with tighter/wider `min`/`max` or allowed-operation sets per difficulty tier, rather than forking task types — keeps the catalog size manageable as you scale grade coverage.
6. **Excluded by design:** graph plotting/sketching, geometric construction, open-ended proofs, "explain why," and anything with multiple *equally valid but structurally different* correct answers unless you explicitly define all accepted canonical forms (e.g., accept both `3/4` and `0.75` for a percentage task, via an OR of validators).
