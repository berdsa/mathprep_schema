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
