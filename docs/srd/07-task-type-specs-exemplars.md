# 07 — Wave-A Exemplar Task-Type Specs

*Five fully-specced types (renamed from "Tier-1" to avoid the Tier/Wave terminology collision fixed this pass — see `00-scope-lock.md`). These are the template the remaining Wave-A backlog replicates, and the reference implementation for Phase 1 of `08-developer-backlog.md`. Each spec's `locale` and `render_target` fields are now explicit columns per the architecture update (findings A, B).*

## G3-NUM-001 — Multi-digit addition with carry

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Addition of two 3-digit numbers requiring carry / NUM / 3 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"{a} + {b} = ?"`; alt-text `"Сложение: {a} плюс {b}"` |
| Variables | `a: int [100,899]`; `b: int [100,899]` |
| Generation constraint | reject-and-retry until ≥1 carry occurs; T2 additionally requires cascade into a 4th digit |
| Solution | `c = a + b` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; strip trim/leading `+`/leading zeros; any `,`/`.` ⇒ `WRONG_FORMAT`; max length 6 |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independent big-int recompute; assert ≥1 carry; 1000/1000 required |
| Tiers | T1: `a,b∈[100,899]`, 1–2 carries. T2: forces cascade into a 4th digit |
| Instance space | T1 ≥100,000 (est.). T2 ≥5,000 (est.). Dedup `(type_id,a,b)`, cooldown 30 days |
| Worked examples | `134+219=353`; `257+486=743` (wrong: `"734"` transposition → INCORRECT); T2 edge `995+108=1103`, input `"01103"` → strip → CORRECT |
| Misconception tags | `MISC-CARRY-DROP`, `MISC-DIGIT-TRANSPOSE` |

## G3-NUM-014 — Division with remainder

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | `a ÷ b`, `b ∤ a` / NUM / 3 / Apply |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Variables | `a∈[10,99]`, `b∈[2,9]`, reject if `a mod b == 0` |
| Solution | `TUPLE(quotient, remainder)` |
| equivalence_policy | **STRICT-FORM** — order fixed |
| Input contract | `^\s*([0-9]{1,3})\s*(?:,\|;\|ост\.?\|остаток)\s*([0-9]{1,3})\s*$`, case-insensitive; bare number ⇒ `INCOMPLETE_TUPLE` |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, INCOMPLETE_TUPLE` |
| Verification oracle | recompute via stdlib integer division; assert `0 ≤ remainder < b`; 1000/1000 |
| Tiers | T1: `a∈[10,99], b∈[2,9]` |
| Instance space | ≥600 valid pairs (est.). Dedup `(type_id,a,b)`, cooldown 30 days |
| Worked examples | `53÷6=8 ост 5`; `97÷8=12 ост 1`; edge `11÷9=1 ост 2` |
| Misconception tags | `MISC-REMAINDER-OMIT`, `MISC-REMAINDER-GE-DIVISOR` |

## G6-FRA-003 — Fraction addition, unlike denominators, proper result

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | `a/b + c/d`, `b≠d` / FRA / 6 / Apply |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Variables | `a<b`, `c<d`, `b≠d`, `b,d∈[2,12]` |
| Generation constraint | reject if sum `≥1` (kept proper; improper/mixed is a separate backlog type, `G6-FRA-004`, not specced here) |
| Solution | `p/q = reduce(a·d+c·b, b·d)` |
| equivalence_policy | **STRICT-FORM** — reduction to lowest terms *is* the assessed skill |
| Input contract | `^\s*([0-9]+)\s*/\s*([0-9]+)\s*$`; OR-of-validators: bare integer accepted if `q` reduces to 1; **decimal equivalents deliberately not accepted** |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | independent rational-arithmetic recompute; assert `gcd(p,q)=1`; assert `p/q<1`; 1000/1000 |
| Instance space | ≥300 valid combinations (est.). Dedup `(type_id,a,b,c,d)`, cooldown 30 days |
| Worked examples | `1/4+1/6=5/12`; `1/6+1/3=1/2`, input `"3/6"` → INCORRECT/`CANON_NOT_REDUCED`; edge (LCM=larger denom) `3/4+1/8=7/8` |
| Misconception tags | `MISC-DENOM-ADD`, `MISC-UNREDUCED` |

## G6-GEO-009 — Point quadrant identification

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Which quadrant/axis is `(x,y)` in / GEO / 6 / Understand |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext` |
| equivalence_policy | **STRICT-FORM** via enumerated whitelist (BOOL) |
| Input vocabulary | `{I, II, III, IV, Ox, Oy, O}`, synonyms mapped case-insensitively |
| Generation constraint | T1: `x,y≠0`, proper quadrants, `x,y∈[±1,±10]`. T2: axis/origin cases placed **by construction**, not left to chance: `x=0,y∈[±1,±150]`; `y=0,x∈[±1,±150]`; and the single origin case `(0,0)` |
| Verification oracle | independent `sign(x),sign(y)` lookup; assert output always in the 7-value whitelist; assert T1 never emits axis/origin; 1000/1000 per tier |
| Instance space | T1: 400 (est.), PASS. **T2: 601 (300+300+1), PASS — but the origin sub-case has `\|S\|=1` by mathematical necessity and will always repeat; declared exception, not a defect** |
| Worked examples | `(3,5)→I`; `(-4,2)→II`; T2 edge `(0,4)→Oy` |
| Misconception tags | `MISC-SIGN-SWAP`, `MISC-AXIS-AS-QUADRANT` |

## G6-GEO-001 — Point quadrant identification

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Which quadrant/axis is `(x,y)` in / GEO / 6 / Understand |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Which quadrant or axis contains ({x}, {y})?` |
| Variables | `x,y: int [-10,10]` for T1; T2 includes axis and origin cases with coordinates in `[-150,150]` |
| Generation constraint | T1 samples nonzero coordinates and therefore emits only quadrants. T2 constructs quadrant, axis, and origin cases explicitly; no case is left to chance. |
| Solution | `I` if `x>0,y>0`; `II` if `x<0,y>0`; `III` if `x<0,y<0`; `IV` if `x>0,y<0`; `Ox` if `y=0,x≠0`; `Oy` if `x=0,y≠0`; `O` if `x=y=0` |
| equivalence_policy | **STRICT-FORM** via the shared BOOL whitelist |
| Input contract | `^\s*(I|II|III|IV|Ox|Oy|O)\s*$`; case-insensitive; surrounding whitespace accepted; no prose synonyms |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently map the signs of persisted `x,y`; assert T1 never emits axis/origin and T2 covers all seven output values; 1000/1000 per tier |
| Instance space | T1: 400 ordered nonzero coordinate pairs. T2: 400 quadrant pairs plus 600 axis points and one origin; the origin repetition is a declared mathematical exception. |
| Worked examples | `(3,5)→I`; `(-4,2)→II`; `(0,4)→Oy` |
| Misconception tags | `MISC-SIGN-SWAP`, `MISC-AXIS-AS-QUADRANT`, `MISC-ORIGIN-OMISSION` |

## G6-GEO-002 — Distance between two points

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Distance between two points / GEO / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Distance between ({x1}, {y1}) and ({x2}, {y2}) = ?` |
| Variables | `x1,y1,x2,y2: int [-10,10]`, with distinct points |
| Generation constraint | Reject equal points; compute the positive Euclidean distance from the coordinate differences. |
| Solution | `sqrt((x2-x1)^2 + (y2-y1)^2)` |
| equivalence_policy | **EQUIV-CLASS** within `1e-6` via the shared TOL validator |
| Input contract | `^\s*[0-9]+(?:[.,][0-9]+)?\s*$`; decimal comma or point accepted; surrounding whitespace accepted |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently recompute the Euclidean distance from persisted coordinates; two batches of 1000 required |
| Tiers | T1/T2: coordinates in `[-10,10]`; tier metadata changes assignment difficulty only |
| Instance space | `21^4-21^2 = 194,040` ordered distinct point pairs; dedup `(type_id,x1,y1,x2,y2)` |
| Worked examples | `(0,0)` to `(3,4)` → `5`; `(1,1)` to `(4,5)` → `5`; `(0,0)` to `(1,1)` → `1.414213562` |
| Misconception tags | `MISC-DISTANCE-MANHATTAN`, `MISC-SQUARE-ROOT`, `MISC-COORDINATE-SUBTRACTION` |

## G6-SP-001 — Basic single-event probability

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Probability of one die outcome / SP / 6 / Understand |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `What is the probability of rolling {face} on a fair six-sided die?` |
| Variables | `face: int [1,6]` |
| Generation constraint | Select one face uniformly; all six outcomes are equally likely. |
| Solution | `1/6` |
| equivalence_policy | **STRICT-FORM** exact rational in lowest terms via the shared EXACT-RAT validator |
| Input contract | `^\s*([0-9]+)(?:\s*/\s*([0-9]+))?\s*$`; bare integer accepted only when the correct rational has denominator 1; decimal equivalents rejected |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | independently recompute one favorable outcome over six equally likely outcomes; two batches of 1000 required |
| Tiers | T1/T2: `face∈[1,6]`; tier metadata controls assignment difficulty only |
| Instance space | exactly six face prompts |
| Worked examples | `face 1→1/6`; `face 4→1/6`; `face 6→1/6` |
| Misconception tags | `MISC-FAVORABLE-OUTCOMES`, `MISC-PROBABILITY-ONE`, `MISC-DENOMINATOR` |

## G6-MD-001 — Volume of a rectangular prism

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Volume of a rectangular prism / MD / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Dimensions {a} × {b} × {c} — volume?` |
| Variables | `a,b,c: int [1,20]` |
| Generation constraint | Sample three positive integer dimensions and compute `a·b·c`. |
| Solution | `a·b·c` cubic units |
| equivalence_policy | **STRICT-FORM** via the shared EXACT-INT validator |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; decimal and unit text rejected |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently multiply the three persisted dimensions; two batches of 1000 required |
| Tiers | T1/T2: `a,b,c∈[1,20]`; tier metadata controls assignment difficulty only |
| Instance space | exactly `20^3 = 8,000` ordered dimension triples |
| Worked examples | `2×3×4→24`; `1×5×10→50`; `20×20×20→8000` |
| Misconception tags | `MISC-OMIT-DIMENSION`, `MISC-ADD-DIMENSIONS`, `MISC-AREA-AS-VOLUME` |

## G6-GEO-003 — Missing triangle angle

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Missing angle in a triangle / GEO / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Triangle angles are {a}° and {b}°. The missing angle?` |
| Variables | `a,b: int [1,178]`, with `a+b<180` |
| Generation constraint | Sample two positive known angles whose sum is less than 180°. |
| Solution | `180-a-b` degrees |
| equivalence_policy | **STRICT-FORM** via the shared EXACT-INT validator |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; degree symbols and decimal input rejected |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently subtract the two persisted angles from 180°; two batches of 1000 required |
| Tiers | T1/T2: same triangle constraints; tier metadata controls assignment difficulty only |
| Instance space | `15,753` valid ordered angle pairs under `a+b<180` |
| Worked examples | `60°,70°→50°`; `90°,45°→45°`; `1°,1°→178°` |
| Misconception tags | `MISC-ANGLE-SUM`, `MISC-SUBTRACTION-ORDER`, `MISC-REFLEX-ANGLE` |

## G6-MD-002 — Unit conversion

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Convert between metres and centimetres / MD / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Convert {value} {from} to {to}.` |
| Variables | `value: int [1,999]`; direction is `cm→m` or `m→cm` |
| Generation constraint | Select a positive integer value and one of the two supported directions. |
| Solution | `value/100` for `cm→m`; `value×100` for `m→cm` |
| equivalence_policy | **EQUIV-CLASS** within `1e-6` via the shared TOL validator |
| Input contract | decimal numeric text with `.` or `,` separator; surrounding whitespace accepted |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently apply the selected conversion factor; two batches of 1000 required |
| Tiers | T1/T2: `value∈[1,999]`; tier metadata controls assignment difficulty only |
| Instance space | 1,998 ordered value/direction pairs |
| Worked examples | `250 cm→2.5 m`; `3 m→300 cm`; `1 cm→0.01 m` |
| Misconception tags | `MISC-FACTOR-INVERSE`, `MISC-DECIMAL-PLACE`, `MISC-UNIT-SWAP` |

## G7-EE-001 — Linear equation (1 variable)

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Solve a one-variable linear equation / EE / 7 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a}x + {b} = {c}` |
| Variables | `a∈[1,10]`, `x∈[1,10]`, `b∈[1,20]`, `c=a·x+b` |
| Generation constraint | Construct `c` from a positive integer solution so division is exact. |
| Solution | `x=(c-b)/a` |
| equivalence_policy | **STRICT-FORM** exact rational via the shared EXACT-RAT validator |
| Input contract | shared exact-rational numeric/fraction contract; reduced fractions required; decimal equivalents rejected |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | independently solve by subtracting `b` and dividing by `a`; two batches of 1000 required |
| Tiers | T1/T2: same positive integer-solution bounds |
| Instance space | `10×10×20×10 = 20,000` constructed parameter tuples |
| Worked examples | `2x+3=11→4`; `5x+1=26→5`; `1x+20=30→10` |
| Misconception tags | `MISC-SUBTRACT-CONSTANT`, `MISC-DIVIDE-COEFFICIENT`, `MISC-SIGN-ERROR` |

## G7-EE-002 — Linear system (2 variables)

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Solve a two-variable linear system / EE / 7 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a1}x + {b1}y = {c1}; {a2}x + {b2}y = {c2}` |
| Variables | positive coefficients in `[1,10]`, positive solution `x,y∈[1,10]`; reject zero determinant |
| Generation constraint | Construct both constants from the selected integer solution and reject parallel coefficient rows. |
| Solution | ordered tuple `(x,y)` |
| equivalence_policy | **STRICT-FORM** ordered tuple via the shared TUPLE validator |
| Input contract | ordered integer tuple with comma or `x,y` separator; surrounding whitespace accepted |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently solve using the determinant formula and compare both components; two batches of 1000 required |
| Tiers | T1/T2: positive coefficients and solutions in stated bounds |
| Instance space | finite constructed coefficient/solution tuples after determinant rejection |
| Worked examples | `x+y=7; 2x+y=10→(3,4)`; `2x+3y=16; x+y=6→(2,4)`; `x+2y=8; 3x+y=9→(2,3)` |
| Misconception tags | `MISC-DETERMINANT`, `MISC-TUPLE-ORDER`, `MISC-ELIMINATION-SIGN` |

## G7-EE-003 — Quadratic equation

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Solve a quadratic equation / EE / 7 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode / locale / render_target | CODE / `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `x² + {b}x + {c} = 0` |
| Variables | distinct integer roots `r1,r2∈[-10,10]`; `b=-(r1+r2)`, `c=r1·r2` |
| Generation constraint | Reject equal roots so the answer is a two-member set. |
| Solution | unordered set `{r1,r2}` |
| equivalence_policy | **STRICT-FORM** unordered integer set via the shared SET validator |
| Input contract | comma-, semicolon-, or whitespace-separated integer roots; duplicates rejected |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently multiply `(x-r1)(x-r2)` and verify both roots; two batches of 1000 required |
| Tiers | T1/T2: distinct roots in `[-10,10]` |
| Instance space | `21×20 = 420` ordered root draws before set normalization |
| Worked examples | `x²-7x+12=0→{3,4}`; `x²+x-6=0→{-3,2}`; `x²- x-20=0→{-4,5}` |
| Misconception tags | `MISC-ROOT-SIGN`, `MISC-FACTOR-PAIR`, `MISC-SET-ORDER` |

## G7-EE-004 — Quadratic inequality

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Solve a quadratic inequality / EE / 7 / Analyze |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `x² + {b}x + {c} > 0` |
| Variables | roots `r1<r2` in `[1,10]`; `b=-(r1+r2)`, `c=r1·r2` |
| Solution / equivalence_policy | `(-∞,r1) ∪ (r2,∞)`; **STRICT-FORM** canonical interval |
| Input contract | canonical interval text; this implementation emits the right-open branch `({r2},∞)` for the positive-side prompt |
| Generation constraint | use `x² + {b}x + {c} > 0` and ask for the positive solution branch `x>{r2}` |
| Verdict model / oracle | `OK, VALUE_MISMATCH, WRONG_FORMAT`; independently verify the selected root boundary; two batches of 1000 |
| Worked examples | `x²-7x+12>0→(4,∞)`; `x²-5x+6>0→(3,∞)`; `x²-3x+2>0→(2,∞)` |
| Misconception tags | `MISC-SIGN-CHART`, `MISC-ROOT-BOUNDARY`, `MISC-OPEN-CLOSED` |

## G7-EE-005 — Linear inequality

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Solve a linear inequality / EE / 7 / Apply |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{a}x + {b} ≤ {c}` |
| Variables | `a∈[1,10]`, boundary `k∈[-10,10]`, `b∈[1,20]`, `c=a·k+b` |
| Solution / equivalence_policy | `(-∞,k]`; **STRICT-FORM** canonical interval |
| Input contract | `^\s*\(\s*-∞\s*,\s*(-?[0-9]+)\s*\]\s*$` |
| Verdict model / oracle | `OK, VALUE_MISMATCH, WRONG_FORMAT`; independently recompute `(c-b)/a`; two batches of 1000 |
| Worked examples | `2x+3≤11→(-∞,4]`; `5x+1≤26→(-∞,5]`; `x+20≤10→(-∞,-10]` |
| Misconception tags | `MISC-INEQUALITY-DIRECTION`, `MISC-ENDPOINT`, `MISC-SUBTRACT-CONSTANT` |

## G7-EE-006 — Exponent rules

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Apply the product rule for exponents / EE / 7 / Apply |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `a^m × a^n = ?` |
| Variables | `a∈[2,5]`, `m,n∈[1,5]` |
| Solution | `a^(m+n)` evaluated as an exact integer |
| equivalence_policy | **STRICT-FORM** via the shared EXACT-INT validator |
| Input contract | shared exact-integer contract |
| Verdict model / oracle | `OK, VALUE_MISMATCH, WRONG_FORMAT`; independently compute both powers and product; two batches of 1000 |
| Instance space | `4×5×5 = 100` tuples |
| Worked examples | `2^3×2^4→128`; `3^2×3^1→27`; `5^1×5^2→125` |
| Misconception tags | `MISC-EXPONENT-ADD`, `MISC-BASE-MULTIPLY`, `MISC-EXPONENT-MULTIPLY` |

## G3-NUM-005 — Simple word problem (addition/subtraction) [HYBRID-AI]

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Narrative add/sub word problem / NUM / 3 / Apply |
| generation_mode | **HYBRID-AI**, `authoring_time: true` (ADR-005) |
| locale / render_target | `ru-KZ` / `plaintext` |
| Answer-first construction | operands and answer chosen by CODE first; AI only wraps them in narrative, never invents/verifies a number |
| Prompt profile ID | `PP-WORDPROB-ADDSUB-01` |
| Provider | "Luna" per prior routing hypothesis — `[UNVERIFIED]`, gated by `OPEN-03` |
| Automated validation gate | narrative must contain both operand values verbatim; failing narratives reject-and-retry or fall back to a MANUAL template pool |
| Human-review policy | 100% review before FINAL; any spec_version bump re-triggers review; post-FINAL 5% monthly sample |
| Benchmark requirement | gold set of 50 hand-written `ru-KZ` word problems before exiting GATED |
| Unit cost per item | **`[OPEN]`** — no measured figure exists; do not ship to production until measured against `OPEN-03`'s benchmark |
| Variables / equivalence_policy | inherited from `G3-NUM-001` (same `a,b`, same STRICT-FORM integer answer) — instance space and oracle not restated |
| Edge cases | narrative-generation failure at authoring time only — no AI call happens per served instance (ADR-005), so this can never be a runtime failure |

*Remaining Wave-A backlog (grade-3 and grade-6 rows of `math-task-catalog.md` not yet specced) follows this same field template — see `08-developer-backlog.md` for the sequencing.*

## G3-NUM-012 — Roman numeral conversion

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Convert an integer to a Roman numeral / NUM / 3 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Convert {n} to a Roman numeral.`; alt-text `Перевод числа {n} в римскую запись` |
| Variables | `n: int [1,3999]` |
| Generation constraint | sample uniformly from the inclusive range; emit canonical subtractive notation (`IV`, `IX`, `XL`, `XC`, `CD`, `CM`) |
| Solution | canonical Roman representation of `n` |
| equivalence_policy | **STRICT-FORM** — canonical Roman spelling is the assessed skill |
| Input contract | `^\s*([MDCLXVI]+)\s*$`; trim surrounding whitespace, case-fold to uppercase, reject non-canonical or out-of-range forms |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently convert `n` using a value/symbol table; assert parse(convert(n)) = n and canonical(convert(n)) = convert(n); 1000/1000 per seed batch |
| Tiers | T1/T2: `n∈[1,3999]`; tiers differ only in assignment difficulty metadata |
| Instance space | exactly 3,999 values; dedup `(type_id,n)`, cooldown 30 days |
| Worked examples | `4→IV`; `944→CMXLIV`; edge `3999→MMMCMXCIX` |
| Misconception tags | `MISC-ROMAN-ADDITIVE`, `MISC-ROMAN-SUBTRACTIVE`, `MISC-ROMAN-NONCANONICAL` |

## G3-NUM-013 — Simple sequence pattern

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the next term in an arithmetic or geometric sequence / NUM / 3 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{mode} pattern: {t1}, {t2}, {t3}, {t4}, ... next?` |
| Variables | Arithmetic: `a∈[0,20]`, `d∈[1,10]`; geometric: `a∈[1,5]`, `r∈[2,5]` |
| Generation constraint | choose arithmetic or geometric uniformly; construct four terms and require the fifth term `≤100` |
| Solution | arithmetic `a+4d`; geometric `a·r^4` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT normalization; decimal and sequence text answers are rejected |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently recompute the selected recurrence from stored `mode`, `a`, and `step`; 1000/1000 per seed batch |
| Tiers | T1/T2: same bounds; tier metadata controls assignment difficulty |
| Instance space | arithmetic 210 valid pairs plus geometric 6 valid pairs, 216 combinations total |
| Worked examples | `2,5,8,11→14`; `1,2,4,8→16`; edge `5,20,80,?` is excluded because the fifth term exceeds 100 |
| Misconception tags | `MISC-SEQUENCE-DIFFERENCE`, `MISC-SEQUENCE-RATIO`, `MISC-OFF-BY-ONE-TERM` |

## G3-NUM-015 — Missing factor

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the missing factor / NUM / 3 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a} × ? = {c}` |
| Variables | `a∈[2,10]`, `factor∈[1,10]`, `c=a·factor` |
| Generation constraint | `c≤100`; construct `c` from the two factors so divisibility is guaranteed |
| Solution | `factor=c/a` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT normalization |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently divide `c` by `a` and assert zero remainder; 1000/1000 per seed batch |
| Tiers | T1/T2: `a∈[2,10]`, `factor∈[1,10]` |
| Instance space | exactly 90 `(a,factor)` combinations |
| Worked examples | `3×?=21→7`; `10×?=100→10`; edge `2×?=2→1` |
| Misconception tags | `MISC-MULTIPLICATION-FACT`, `MISC-DIVISION-INVERSE`, `MISC-PLACE-VALUE` |

## G3-NUM-016 — Missing divisor

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the missing divisor / NUM / 3 / Apply |
| spec_version / generation_mode | 1.0.0-draft / CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template / variables | `{a} ÷ ? = {c}`; divisor and quotient `∈[1,10]`, `a=divisor·c` |
| Solution / equivalence_policy | `a/c`; **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$` |
| Verification oracle | independently construct and divide; 1000/1000 per seed batch |
| Instance space / examples | 100 pairs; `21÷?=3→7`, `100÷?=10→10`, `2÷?=2→1` |
| Misconception tags | `MISC-DIVISOR-DIVIDEND-SWAP`, `MISC-FACT-FAMILY` |

## G3-NUM-017 — Missing dividend

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the missing dividend / NUM / 3 / Apply |
| spec_version / generation_mode | 1.0.0-draft / CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template / variables | `? ÷ {b} = {c}`; `b,c∈[1,10]`, dividend `a=b·c≤100` |
| Solution / equivalence_policy | `b·c`; **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$` |
| Verification oracle | independently multiply divisor and quotient; 1000/1000 per seed batch |
| Instance space / examples | 100 pairs; `?÷7=3→21`, `?÷10=10→100`, `?÷2=1→2` |
| Misconception tags | `MISC-DIVIDEND-DIVISOR-SWAP`, `MISC-MULTIPLICATION-FACT` |

## G3-NUM-018 — Multiplication as repeated addition

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Model multiplication as repeated addition / NUM / 3 / Understand |
| spec_version / generation_mode | 1.0.0-draft / CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template / variables | `{a} groups of {b}: {b} + ... = ?`; `a∈[2,5]`, `b∈[2,10]` |
| Solution / equivalence_policy | `a·b`; **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$` |
| Verification oracle / space | independent multiplication; 1000/1000 per seed batch; 36 combinations |
| Worked examples / misconceptions | `3 groups of 4→12`; `5 groups of 10→50`; `2 groups of 2→4`; `MISC-COUNT-GROUPS`, `MISC-ADD-FACTOR` |

## G3-NUM-019 — Division as sharing

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Share a quantity equally / NUM / 3 / Apply |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template / variables | `{n} items shared equally among {g} groups. Each group?`; `g∈[2,10]`, `each∈[1,10]`, `n=g·each≤100` |
| Solution / policy / input contract | `n/g`; **STRICT-FORM**; `^\s*\+?0*([0-9]{1,5})\s*$` |
| Verification / space / examples | independent division, 1000/1000 per batch; 90 pairs; `12÷3→4`, `100÷10→10`, `2÷2→1` |
| Misconceptions | `MISC-DIVISION-SHARING`, `MISC-GROUP-COUNT` |

## G3-NUM-020 — Multiplication word problem

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Equal bags and items / NUM / 3 / Apply |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template / variables | `{a} bags with {b} apples each. Total apples?`; `a,b∈[2,10]` |
| Solution / policy / input contract | `a·b`; **STRICT-FORM**; `^\s*\+?0*([0-9]{1,5})\s*$` |
| Verification / space / examples | independent multiplication, 1000/1000 per batch; 81 pairs; `2×3→6`, `10×10→100`, `5×7→35` |
| Misconceptions | `MISC-FACTOR-COUNT`, `MISC-ADD-INSTEAD-MULTIPLY` |

## G3-NUM-021 — Division word problem

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Equal cookie sharing / NUM / 3 / Apply |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template / variables | `{n} cookies shared among {g} kids. Each gets?`; `g∈[2,10]`, `each∈[1,10]`, `n=g·each≤100` |
| Solution / policy / input contract | `n/g`; **STRICT-FORM**; `^\s*\+?0*([0-9]{1,5})\s*$` |
| Verification / space / examples | independent division, 1000/1000 per batch; 90 pairs; `12÷3→4`, `100÷10→10`, `2÷2→1` |
| Misconceptions | `MISC-SHARING-UNEQUAL`, `MISC-DIVISOR-QUOTIENT` |

## G1-NUM-001 — Addition within range

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Addition within 0–20 / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"{a} + {b} = ?"`; alt-text `"Сложение: {a} плюс {b}"` |
| Variables | `a: int [0,20]`; `b: int [0,20]` |
| Generation constraint | Uniform deterministic draw of both operands from the inclusive range; no rejection is needed. |
| Solution | `c = a + b` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; strip trim/leading `+`/leading zeros; any `,`/`.` ⇒ `WRONG_FORMAT`; max length 6 |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independent recompute from persisted `a,b`; assert both operands and answer are in range; two batches of 1000 required |
| Tiers | T1: `a,b∈[0,20]`; T2 uses the same parameter space with mixed carries encouraged by seed selection. |
| Instance space | 441 ordered operand pairs (exact); dedup `(type_id,a,b)`, cooldown 30 days |
| Worked examples | `3+4=7`; `0+19=19` (input `"019"` → strip → CORRECT); `12+8=20` (wrong: `"21"` → INCORRECT) |
| Misconception tags | `MISC-ADD-FACT`, `MISC-PLACE-VALUE`, `MISC-OFF-BY-ONE` |

## G1-NUM-002 — Subtraction within range

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Subtraction within 0–20 without negative result / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"{a} − {b} = ?"`; alt-text `"Вычитание: {a} минус {b}"` |
| Variables | `a: int [0,20]`; `b: int [0,20]`; swap so `a≥b` |
| Generation constraint | Deterministic draw, then order operands so the result is non-negative. |
| Solution | `c = a − b` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; strip trim/leading `+`/leading zeros; any `,`/`.` ⇒ `WRONG_FORMAT`; max length 6 |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently redraw/order operands and recompute; two batches of 1000 required |
| Tiers | T1: `a,b∈[0,20]`, `a≥b`; T2 same space. |
| Instance space | 231 ordered pairs with `a≥b` (exact) |
| Worked examples | `9−4=5`; `7−7=0`; `20−3=17` (wrong `16` → INCORRECT) |
| Misconception tags | `MISC-SUBTRACT-BORROW`, `MISC-OPERAND-ORDER`, `MISC-OFF-BY-ONE` |

## G1-NUM-003 — Number comparison

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Compare two whole numbers / NUM / 1–2 / Understand |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"Compare {a} and {b}: <, >, ="` |
| Variables | `a,b: int [0,20]` |
| Generation constraint | Uniform deterministic draw; answer is the one of `<`, `>`, `=` selected by integer comparison. |
| Solution | compare `a` and `b` directly |
| equivalence_policy | **STRICT-FORM** via BOOL whitelist |
| Input contract | `<`, `>`, `=`, plus `less`, `less than`, `greater`, `greater than`, `equal`, `equal to`, case-insensitive |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independently compare persisted operands; two batches of 1000 required |
| Tiers | T1/T2: `a,b∈[0,20]` |
| Instance space | 441 ordered operand pairs (exact) |
| Worked examples | `3,7→<`; `9,4→>`; `5,5→=` |
| Misconception tags | `MISC-SIGN-DIRECTION`, `MISC-EQUALITY-OVERUSE` |

## G1-NUM-004 — Missing addend

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the missing addend / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"{a} + ? = {c}"` |
| Variables | `a,c: int [0,20]`, reordered so `c≥a` |
| Generation constraint | Deterministically draw two values and reorder; answer is `c−a`. |
| Solution | `x = c − a` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently reorder and subtract; two batches of 1000 required |
| Tiers | T1/T2: `0≤a≤c≤20` |
| Instance space | 231 ordered `(a,c)` pairs (exact) |
| Worked examples | `3+?=7→4`; `0+?=0→0`; `12+?=20→8` |
| Misconception tags | `MISC-INVERSE-OPERATION`, `MISC-SUBTRAHEND-CONFUSION` |

## G1-NUM-005 — Simple word problem (addition/subtraction)

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | One-step apple add/subtraction story / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Had {a} apples, got {b} / gave away {b}. How many now?` |
| Variables | `a,b: int [0,20]`; subtraction reordered so `a≥b`; operation ∈ {add, subtract} |
| Generation constraint | Choose operands and operation deterministically; answer-first values are inserted into a fixed narrative template. |
| Solution | `a+b` for got-more, `a−b` for gave-away |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently redraw operation/operands and recompute; two batches of 1000 required |
| Tiers | T1/T2: operands in `[0,20]`, subtraction non-negative |
| Instance space | 441 add cases plus 231 subtraction cases (exact) |
| Worked examples | `Had 3, got 4→7`; `Had 9, gave away 4→5`; `Had 0, got 0→0` |
| Misconception tags | `MISC-WORD-OPERATION`, `MISC-SUBTRACTION-DIRECTION` |

## G1-NUM-006 — Place value

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Digit in ones, tens, or hundreds place / NUM / 1–2 / Understand |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `What digit is in the {ones/tens/hundreds} place of {n}?` |
| Variables | `n∈[0,999]`; position ∈ {ones,tens,hundreds} |
| Generation constraint | Uniform deterministic draw of `n` and position. |
| Solution | `floor(n/10^p) mod 10` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independent digit extraction; two batches of 1000 required |
| Tiers | T1/T2: `n∈[0,999]` |
| Instance space | 3000 `(n,position)` combinations (exact) |
| Worked examples | tens digit of `347` → `4`; hundreds digit of `805` → `8`; ones digit of `0` → `0` |
| Misconception tags | `MISC-PLACE-SHIFT`, `MISC-ZERO-PLACE` |

## G1-NUM-007 — Ordering a list

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Sort a short list ascending / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Order [{list}] from smallest to largest` |
| Variables | list length 3–5; values ∈ `[0,20]` |
| Generation constraint | Deterministic list draw; correct answer is stable ascending canonical form with spaces. |
| Solution | numeric ascending sort |
| equivalence_policy | **STRICT-FORM** canonical sorted list |
| Input contract | comma/semicolon/space-separated signed integer tokens; canonical output uses one space |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | independent sort; two batches of 1000 required |
| Tiers | T1/T2: list length 3–5, values `[0,20]` |
| Instance space | finite multisets over 21 values for lengths 3–5; exact total 6561+10626+23751 = 40938 sequences before dedup |
| Worked examples | `[3,1,2]→1 2 3`; `[9,4,4]→4 4 9`; `[0,20,7]→0 7 20` |
| Misconception tags | `MISC-SORT-DIRECTION`, `MISC-DUPLICATE-DROP` |

## G1-NUM-008 — Money counting

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Count mixed 1-unit and 5-unit coins / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"{a} coins of {x} + {b} coins of {y} = ?"` |
| Variables | `a,b∈[0,20]`; denominations fixed to `x=1`, `y=5` |
| Generation constraint | Deterministic count draw; answer is total value in units. |
| Solution | `a·1+b·5` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently recompute coin value; two batches of 1000 required |
| Tiers | T1/T2: counts `[0,20]` |
| Instance space | 441 ordered count pairs (exact) |
| Worked examples | `3×1+4×5→23`; `0×1+2×5→10`; `7×1+0×5→7` |
| Misconception tags | `MISC-COIN-COUNT-VALUE`, `MISC-DENOMINATION-SWAP` |

## G1-NUM-009 — Skip counting / next term

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Continue an arithmetic skip-counting sequence / NUM / 1–2 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `"{start}, {start+step}, ... next? (step {step})"` |
| Variables | `start∈[0,20]`; `step∈[1,10]`; shown-term count `∈[2,5]` |
| Generation constraint | Deterministic arithmetic progression; answer is the next term after the shown sequence. |
| Solution | `start + step·count` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently recompute the next arithmetic term; two batches of 1000 required |
| Tiers | T1/T2: `start∈[0,20]`, `step∈[1,10]`, count `[2,5]` |
| Instance space | 21×10×4 = 840 parameter combinations (exact) |
| Worked examples | `2,5,... step 3→8`; `0,10,... step 10→20`; `7,8,... step 1→9` |
| Misconception tags | `MISC-STEP-OFF-BY-ONE`, `MISC-ADD-WRONG-TERM` |

## G1-NUM-010 — Shape property lookup

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Count sides of a named basic shape / GEO / 1–2 / Remember |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `How many sides does a {shape} have?` |
| Variables | shape ∈ {triangle, square, rectangle, pentagon, hexagon} |
| Generation constraint | Deterministic draw from the fixed five-shape vocabulary. |
| Solution | lookup sides `{3,4,4,5,6}` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independent vocabulary lookup; two batches of 1000 required |
| Tiers | T1/T2: fixed vocabulary |
| Instance space | 5 named-shape cases (exact) |
| Worked examples | triangle → 3; rectangle → 4; hexagon → 6 |
| Misconception tags | `MISC-SIDE-VERTEX-CONFUSION`, `MISC-SHAPE-MEMORY` |

## G3-NUM-002 — Multiplication fact

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Multiplication fact / NUM / 3–4 / Recall |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a} × {b} = ?` |
| Variables | `a,b∈[0,12]` |
| Generation constraint | Deterministic ordered-pair draw; answer is the product `a·b`. |
| Solution | `a·b` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently recompute `a·b`; two batches of 1000 required |
| Tiers | T1/T2: factors `[0,12]` |
| Instance space | 13×13 = 169 ordered factor pairs (exact) |
| Worked examples | `3×4→12`; `0×9→0`; `12×12→144` |
| Misconception tags | `MISC-ADDITION-INSTEAD-OF-MULTIPLICATION`, `MISC-FACT-RECALL`, `MISC-OPERAND-ORDER` |

## G3-NUM-003 — Exact division

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Exact division fact / NUM / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a} ÷ {b} = ?` |
| Variables | divisor `b∈[1,12]`; quotient `q∈[0,12]`; dividend `a=b·q` |
| Generation constraint | Deterministic divisor/quotient draw; dividend is constructed so `b∣a`. |
| Solution | `a÷b` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently divide the displayed dividend by divisor; two batches of 1000 required |
| Tiers | T1/T2: divisor `[1,12]`, quotient `[0,12]` |
| Instance space | 12×13 = 156 divisor/quotient pairs (exact) |
| Worked examples | `12÷3→4`; `0÷7→0`; `144÷12→12` |
| Misconception tags | `MISC-DIVISION-AS-MULTIPLICATION`, `MISC-REMAINDER-IGNORED`, `MISC-DIVISOR-DIVIDEND-SWAP` |

## G3-NUM-004 — Multi-digit add/sub (carry/borrow)

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Multi-digit addition or subtraction with carry/borrow / NUM / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a} {op} {b} = ?` |
| Variables | `op∈{+,−}`; `a,b∈[100,999]`; subtraction requires `a≥b` |
| Generation constraint | Addition instances contain at least one carry; subtraction instances contain at least one borrow. |
| Solution | integer sum or difference according to `op` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently recompute operation and carry/borrow predicate; two batches of 1000 required |
| Tiers | T1/T2: three-digit operands; carry/borrow required |
| Instance space | finite accepted ordered triples from 900×900×2, filtered by operation constraints |
| Worked examples | `247+386→633`; `758−269→489`; `995+108→1103` |
| Misconception tags | `MISC-CARRY-DROP`, `MISC-BORROW-DROP`, `MISC-DIGIT-TRANSPOSE` |

## G3-NUM-006 — Order of operations

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Evaluate multiplication/division before addition/subtraction / NUM / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a} + {b} × {c} − {d} ÷ {e} = ?` |
| Variables | `a,b,c,e,q∈[1,9]`; `d=e·q` |
| Generation constraint | Division is exact; standard precedence is required: multiplication/division before addition/subtraction. |
| Solution | `a+b·c−q` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently evaluate with precedence; two batches of 1000 required |
| Tiers | T1/T2: all displayed variables `[1,9]`, exact division |
| Instance space | 9⁵ = 59049 ordered parameter combinations (exact) |
| Worked examples | `2+3×4−8÷2→10`; `9+1×7−6÷3→14`; `5+8×2−9÷3→18` |
| Misconception tags | `MISC-LEFT-TO-RIGHT`, `MISC-DIVISION-PRECEDENCE`, `MISC-DIVISION-TRUNCATION` |

## G3-NUM-007 — Rounding

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Round a whole number to the nearest ten or hundred / NUM / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Round {n} to the nearest {place}` |
| Variables | `n∈[100,999]`; `place∈{10,100}` |
| Generation constraint | Deterministic draw; half cases round upward away from zero. |
| Solution | nearest multiple of `place` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently apply half-up rounding; two batches of 1000 required |
| Tiers | T1/T2: `n∈[100,999]`, place ten or hundred |
| Instance space | 900×2 = 1800 ordered cases (exact) |
| Worked examples | `347→350` nearest 10; `650→700` nearest 100; `999→1000` nearest 10 |
| Misconception tags | `MISC-WRONG-PLACE`, `MISC-DOWN-ON-FIVE`, `MISC-DIGIT-TRUNCATION` |

## G3-NUM-008 — Unit fraction of a quantity

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find one unit fraction of a whole quantity / NUM / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `What is 1/{b} of {n}?` |
| Variables | `b∈[2,9]`; `q∈[1,99]`; `n=b·q` |
| Generation constraint | Deterministic denominator/quotient draw; quantity is divisible by denominator. |
| Solution | `n÷b=q` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently divide `n` by `b`; two batches of 1000 required |
| Tiers | T1/T2: denominator `[2,9]`, quotient `[1,99]` |
| Instance space | 8×99 = 792 denominator/quotient pairs (exact) |
| Worked examples | `1/4 of 20→5`; `1/3 of 27→9`; `1/9 of 81→9` |
| Misconception tags | `MISC-MULTIPLY-INSTEAD-OF-DIVIDE`, `MISC-DENOMINATOR-INVERT`, `MISC-NONDIVISIBLE-ROUNDING` |

## G3-NUM-009 — Perimeter of rectangle/square

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the perimeter from two side lengths / GEO / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Sides {a}, {b} — perimeter?` |
| Variables | `a,b∈[1,20]`; equal sides represent a square |
| Generation constraint | Deterministic side-length draw; perimeter is `2a+2b`. |
| Solution | `2(a+b)` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently apply the perimeter formula; two batches of 1000 required |
| Tiers | T1/T2: side lengths `[1,20]` |
| Instance space | 20×20 = 400 ordered side pairs (exact) |
| Worked examples | `3,4→14`; `5,5→20`; `1,20→42` |
| Misconception tags | `MISC-AREA-INSTEAD-OF-PERIMETER`, `MISC-SIDE-COUNT`, `MISC-ONE-SIDE-OMITTED` |

## G3-NUM-010 — Area of rectangle/square

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find the area from two side lengths / GEO / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `Sides {a}, {b} — area?` |
| Variables | `a,b∈[1,20]`; equal sides represent a square |
| Generation constraint | Deterministic side-length draw; area is `a·b`. |
| Solution | `a·b` |
| equivalence_policy | **STRICT-FORM** |
| Input contract | `^\s*\+?0*([0-9]{1,5})\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | independently apply the area formula; two batches of 1000 required |
| Tiers | T1/T2: side lengths `[1,20]` |
| Instance space | 20×20 = 400 ordered side pairs (exact) |
| Worked examples | `3,4→12`; `5,5→25`; `1,20→20` |
| Misconception tags | `MISC-PERIMETER-INSTEAD-OF-AREA`, `MISC-SIDE-COUNT`, `MISC-ONE-SIDE-OMITTED` |

## G3-NUM-011 — Division with remainder

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Divide with quotient and remainder / NUM / 3–4 / Apply |
| Provenance / ref_status | seed, `[SOURCED: REF-01]` — grade alignment `[UNVERIFIED]` pending MISS-01 |
| spec_version | 1.0.0-draft |
| generation_mode | CODE |
| locale / render_target | `ru-KZ` / `plaintext`, `unicode-math` |
| Template | `{a} ÷ {b} = ? remainder ?` |
| Variables | `a∈[10,99]`; `b∈[2,9]`; reject exact division |
| Generation constraint | `a mod b != 0`; answer is ordered `(quotient,remainder)`, with `0≤remainder<b`. |
| Solution | `TUPLE(a÷b,a mod b)` |
| equivalence_policy | **STRICT-FORM** ordered tuple |
| Input contract | `^\s*([0-9]{1,3})\s*(?:,|;|ост\.?|остаток)\s*([0-9]{1,3})\s*$`; bare number is `INCOMPLETE_TUPLE` |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, INCOMPLETE_TUPLE` |
| Verification oracle | independently recompute quotient/remainder; two batches of 1000 required |
| Tiers | T1/T2: `a∈[10,99]`, `b∈[2,9]` |
| Instance space | 720 ordered candidates minus 167 exact-division pairs = 553 valid ordered pairs (exact) |
| Worked examples | `53÷6→8,5`; `97÷8→12,1`; `11÷9→1,2` |
| Misconception tags | `MISC-REMAINDER-OMIT`, `MISC-REMAINDER-GE-DIVISOR`, `MISC-DIVISOR-DIVIDEND-SWAP` |

## G6-DEC-001 — Decimal arithmetic

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Decimal addition, subtraction, multiplication, or division / DEC / 6 / Apply |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{a} {operation} {b} = ?` |
| Variables / constraint | `a,b∈[1.0,99.9]` with one decimal place; operation chosen from `+,-,×,÷`; division rejects zero divisor |
| Solution / equivalence_policy | ordinary decimal arithmetic; **EQUIV-CLASS** within `1e-6` |
| Input contract | decimal numeric text with `.` or `,` separator; surrounding whitespace accepted |
| Verdict model / oracle | `OK, VALUE_MISMATCH, WRONG_FORMAT`; independent float recompute, 1000/1000 per seed batch |
| Worked examples | `1.2+3.4=4.6`; `9.0-2.5=6.5`; `2.5×4.0=10.0` |
| Misconception tags | `MISC-DECIMAL-PLACE`, `MISC-OPERATION-SIGN`, `MISC-DIVIDE-BY-ZERO` |

## G6-FRA-004 — Fraction multiplication/division

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Multiply or divide fractions / FRA / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{a}/{b} {operation} {c}/{d} = ?` |
| Variables | `a,c∈[1,12]`; `b,d∈[2,12]`; both input fractions proper |
| Generation constraint | choose multiplication or division uniformly; division numerator `c` is nonzero; reduce the stored result |
| Solution | multiply: `reduce(a·c,b·d)`; divide: `reduce(a·d,b·c)` |
| equivalence_policy | **STRICT-FORM** — reduced fraction required |
| Input contract | `^\s*([0-9]+)\s*/\s*([0-9]+)\s*$`; bare integer accepted only when the reduced denominator is 1 |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | independently apply the selected cross-product operation and gcd reduction; 1000/1000 per seed batch |
| Tiers / instance space | T1/T2 use the same bounds; 12×11×12×11×2 generated operation cases before reduction |
| Worked examples | `2/3×3/4=1/2`; `5/6÷2/3=5/4`; edge `1/2×2/12=1/12` |
| Misconception tags | `MISC-FRACTION-INVERT`, `MISC-FRACTION-CROSS-MULTIPLY`, `MISC-UNREDUCED` |

## G6-PCT-001 — Percentage of a number

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Find a percentage of a whole number / DEC / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `What is {p}% of {n}?` |
| Variables | `p∈[1,99]`; `n∈[10,999]`; `p·n` is positive |
| Generation constraint | Draw integer percentage and whole-number operands; compute and reduce the result as a rational number. |
| Solution | `reduce(p·n,100)` |
| equivalence_policy | **STRICT-FORM** — reduced fraction required; bare integer accepted when denominator reduces to 1 |
| Input contract | `^\s*[+-]?[0-9]+(?:\s*/\s*[0-9]+)?\s*$`; shared EXACT-RAT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | Independently compute `p·n/100`, reduce by gcd, and compare; two batches of 1000 required |
| Tiers | T1/T2: `p∈[1,99]`, `n∈[10,999]` |
| Instance space | `99×990 = 98,010` ordered percentage/whole-number pairs (exact) |
| Worked examples | `10% of 80→8`; `25% of 60→15`; `15% of 40→6` |
| Misconception tags | `MISC-PERCENT-DIVIDE-10`, `MISC-PERCENT-MULTIPLY-100`, `MISC-UNREDUCED` |

## G6-PCT-002 — Percentage change

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Apply a percentage increase or decrease / DEC / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{n} increases/decreases by {p}% → ?` |
| Variables | `n∈[10,999]`; `p∈[1,50]`; `direction∈{increase,decrease}` |
| Generation constraint | Draw a positive whole-number base and a percentage change; decrease remains positive. |
| Solution | `n·(100±p)/100`, with `+` for increase and `−` for decrease |
| equivalence_policy | **EQUIV-CLASS** within the shared TOL tolerance `1e-6` |
| Input contract | decimal numeric text with `.` or `,` separator; surrounding whitespace accepted |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT` |
| Verification oracle | Independently recompute the percentage multiplier; two batches of 1000 required |
| Tiers | T1/T2: `n∈[10,999]`, `p∈[1,50]`, either direction |
| Instance space | `990×50×2 = 99,000` ordered base/percentage/direction cases (exact) |
| Worked examples | `100 increases by 10%→110`; `80 decreases by 25%→60`; `50 increases by 15%→57.5` |
| Misconception tags | `MISC-ADD-PERCENT-AS-POINTS`, `MISC-DECREASE-SIGN`, `MISC-DIVIDE-BY-100-TWICE` |

## G6-RAT-001 — Ratio simplification

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Simplify a ratio / RP / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `Simplify {a} : {b}` |
| Variables | `a,b∈[2,99]`; `gcd(a,b)>1` |
| Generation constraint | Draw a positive reducible ratio and divide both terms by their gcd. |
| Solution | `a/g : b/g`, where `g=gcd(a,b)` |
| equivalence_policy | **STRICT-FORM** — reduced canonical ratio required |
| Input contract | `^\s*[0-9]+\s*:\s*[0-9]+\s*$` |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | Independently compute gcd and reduced terms; two batches of 1000 required |
| Tiers | T1/T2: positive two-term ratios in `[2,99]` with nontrivial gcd |
| Instance space | finite accepted ordered pairs from `98×98`, filtered by `gcd(a,b)>1` |
| Worked examples | `6:8→3:4`; `15:25→3:5`; `18:24→3:4` |
| Misconception tags | `MISC-DIVIDE-ONE-TERM`, `MISC-WRONG-GCD`, `MISC-UNREDUCED` |

## G6-RP-001 — Proportion solving

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Solve a one-variable proportion / RP / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{a}/{b} = {c}/x, find x` |
| Variables | `a,b,c∈[1,12]`; `a` divides `b·c`; `a,b,c` positive |
| Generation constraint | Reject non-integral solutions; answer is `x=b·c/a`. |
| Solution | `x = b·c/a` |
| equivalence_policy | **STRICT-FORM** — shared EXACT-RAT canonical integer or reduced fraction |
| Input contract | `^\s*[+-]?[0-9]+(?:\s*/\s*[0-9]+)?\s*$`; shared EXACT-RAT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, CANON_NOT_REDUCED` |
| Verification oracle | Independently recompute `b·c/a` and reduce; two batches of 1000 required |
| Tiers | T1/T2: positive coefficients `[1,12]`, integral solution only |
| Instance space | accepted ordered triples from `12³`, filtered by `a|(b·c)` |
| Worked examples | `2/3=4/x→x=6`; `3/5=6/x→x=10`; `4/9=8/x→x=18` |
| Misconception tags | `MISC-CROSS-MULTIPLY-WRONG`, `MISC-INVERT-PROPORTION`, `MISC-OMIT-DIVISOR` |

## G6-NS-001 — GCD / LCM

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Compute the greatest common divisor or least common multiple / NS / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{operation} of {a} and {b}` |
| Variables | `a,b∈[2,99]`; `operation∈{GCD,LCM}` |
| Generation constraint | Positive integer operands; LCM is computed as `a·b/gcd(a,b)`. |
| Solution | `gcd(a,b)` or `lcm(a,b)` according to operation |
| equivalence_policy | **STRICT-FORM** — canonical integer |
| Input contract | `^\s*\+?0*[0-9]{1,5}\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | Independently compute Euclidean gcd and derived lcm; two batches of 1000 required |
| Tiers | T1/T2: positive operands `[2,99]`, either operation |
| Instance space | `98×98×2 = 19,208` ordered operand/operation cases |
| Worked examples | `GCD of 18 and 24→6`; `LCM of 6 and 8→24`; `GCD of 35 and 49→7` |
| Misconception tags | `MISC-GCD-AS-LCM`, `MISC-LCM-AS-PRODUCT`, `MISC-FACTORIZATION-ERROR` |

## G6-NS-002 — Negative number arithmetic

| Field | Value |
|---|---|
| Title / domain / grade / Bloom | Compute with signed numbers / NS / 6 / Apply |
| Provenance / ref_status | expanded grade-by-grade catalog, `[UNVERIFIED]` pending MISS-01 |
| spec_version / generation_mode / locale | 1.0.0-draft / CODE / `ru-KZ` |
| Template | `{a} {operation} {b} = ?` |
| Variables | `a,b∈[-99,99]\{0}`; `operation∈{+,−,×,÷}`; division requires `a mod b=0` |
| Generation constraint | Draw nonzero signed operands; reject non-integral division. |
| Solution | ordinary signed integer arithmetic |
| equivalence_policy | **STRICT-FORM** — canonical integer |
| Input contract | `^\s*[+-]?0*[0-9]{1,5}\s*$`; shared EXACT-INT contract |
| Verdict model | `OK, VALUE_MISMATCH, WRONG_FORMAT, EMPTY_INPUT, INPUT_TOO_LONG` |
| Verification oracle | Independently recompute the selected signed operation; two batches of 1000 required |
| Tiers | T1/T2: nonzero signed operands in `[-99,99]`, exact division only |
| Instance space | finite accepted signed operand/operator tuples, excluding zero and non-integral divisions |
| Worked examples | `−7+3→−4`; `−6×−5→30`; `−24÷6→−4` |
| Misconception tags | `MISC-SIGN-RULE`, `MISC-NEGATIVE-DIVISION`, `MISC-ABSOLUTE-VALUE` |
