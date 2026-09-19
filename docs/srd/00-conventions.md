# 00 — Conventions

**Status: DRAFT — pending reconciliation with the existing `docs/task-bank-generator/00-conventions.md` (OPEN-07).**

## 1. ID scheme
`G<grade>-<DOMAIN>-<NNN>` for K-12; `U-<COURSE>-<NNN>` for university. Immutable once assigned. `[SOURCED: REF-02]`
DOMAIN ∈ `{NUM, FRA, DEC, GEO, MEA, ALG, FUN, STA, PRO, TRG, LOG, VEC, MAT, CAL, DIS}`.

All IDs issued before `MISS-02` is supplied are **PROVISIONAL** (RISK-002). A PROVISIONAL ID may not be marked `FINAL`.

## 2. Validation-method legend, normalization, and reason codes

Unchanged in substance from the prior pass. Consolidated table (this is now the single normative copy — `backend-integration.md` references it, does not restate it):

| Code | Normalize | Compare | Reason codes |
|---|---|---|---|
| EXACT-INT | trim; strip leading `+`; strip leading zeros; any `,`/`.` present ⇒ reject | integer equality | `WRONG_FORMAT`, `VALUE_MISMATCH` |
| EXACT-RAT | parse `p/q`; reduce via gcd; `q>0`; `q=1` ⇒ canonical bare integer | `(p,q)` equality post-reduction | `WRONG_FORMAT`, `VALUE_MISMATCH`, `CANON_NOT_REDUCED` |
| TOL | parse float per NotationProfile separator | `\|given−correct\| ≤ tol` (default `1e-6`; "round to N" ⇒ `0.5·10⁻ᴺ`) | `WRONG_FORMAT`, `VALUE_MISMATCH` |
| SET | split by declared separator, trim, parse per sub-type | sorted **multiset** equality (duplicates preserved) | `WRONG_FORMAT`, `SET_CARDINALITY_MISMATCH`, `VALUE_MISMATCH` |
| CANON | apply the type's canonical-form grammar (§3) to both sides | exact string equality | `WRONG_FORMAT`, `VALUE_MISMATCH` |
| CAS | *(no consumer until `OPEN-06` closes — do not implement early)* | symbolic equivalence, sandboxed | `CAS_TIMEOUT` (never `INCORRECT`) |
| BOOL | map synonym → canonical enum via declared table, case-insensitive | enum equality against whitelist | `WRONG_FORMAT` |
| TUPLE | split by declared order/separator; per-component sub-validator | ordered component-wise (never sorted) | `WRONG_FORMAT`, `INCOMPLETE_TUPLE`, `VALUE_MISMATCH` |
| MATRIX | *(no consumer yet)* row-major flatten | element-wise, TOL if needed | `WRONG_FORMAT`, `VALUE_MISMATCH` |

## 3. Canonical-form grammar
Unchanged from prior pass — reduced fraction, integer, sorted set, interval, radical, polynomial ordering, matrix/vector row-major. See prior pass content; no new forms introduced this turn.

## 4. Difficulty tier model
`T1` (CORE), `T2` (CHALLENGE), extendable per type. **This is the only sense of "Tier" in this project from this point forward** — the scope-rollout sense is now called **Wave** (see `00-scope-lock.md`).

## 5. NotationProfile — `ru-KZ`
Unchanged from prior pass (decimal comma, space-grouped digits, `;` interval separator, `tg/ctg`, `НОД/НОК`, ASCII-fallback input accepted regardless of display glyph).

## 6. Data-dictionary tables — **new this pass, Phase-0 deliverable**

These are the enumerations previously used only in prose. They now become actual lookup tables (or `CHECK` constraints, developer's call per §9 of `08-developer-backlog.md`), seeded once in `schema`, referenced by both `taskgen` and `grader`.

| Dictionary | Values | Consumer |
|---|---|---|
| `domain` | `NUM, FRA, DEC, GEO, MEA, ALG, FUN, STA, PRO, TRG, LOG, VEC, MAT, CAL, DIS` | `task_type.domain` |
| `grade_band` | `1,2,3,4,5,6,7,8,9,10,11,UNIVERSITY` | `task_type.grade` |
| `tier_code` | `T1, T2, T3` | `task_instance.tier` |
| `validation_method` | `EXACT-INT, EXACT-RAT, TOL, SET, CANON, CAS, BOOL, TUPLE, MATRIX` | `task_type.validation_method` |
| `equivalence_policy` | `STRICT-FORM, EQUIV-CLASS, CAS-EQUIV` — **no default row is ever treated as a fallback; every `task_type` row must set this explicitly** | `task_type.equivalence_policy` |
| `generation_mode` | `CODE, HYBRID-AI` (AI-only, uncontrolled, is never a valid value — cartridge rule) | `task_type.generation_mode` |
| `task_type_status` | `DRAFT, GATED, FINAL` — only `FINAL` (and, for the family pilot, `GATED` per ASM-08) may be loaded into a service's active registry | `task_type.status` |
| `verdict` | `CORRECT, INCORRECT, UNPARSEABLE` | `submission.verdict` |
| `reason_code` | `OK, PARSE_ERROR, EMPTY_INPUT, INPUT_TOO_LONG, WRONG_FORMAT, VALUE_MISMATCH, CANON_NOT_REDUCED, INCOMPLETE_TUPLE, SET_CARDINALITY_MISMATCH, CAS_TIMEOUT` — extend only by adding a row and documenting it here | `submission.reason_code` |
| `render_target` | `plaintext, unicode-math` (Wave A/B); `latex, html-mathml` reserved, not seeded yet | `task_instance.render_target` |
| `locale` | `ru-KZ` (seeded); `kk-KZ` reserved, not seeded yet (OOS-08) | `task_instance.locale`, `task_type.locale` |
| `user_type` *(new, per this pass — see finding G)* | `STUDENT, GUARDIAN, ADMIN` — only `STUDENT` is exercised by any FR in this pack; the other two are declared so the column never needs an unplanned migration when the client-access-expansion track needs them | `users.user_type` |

`[DERIVED]` — none of these value sets were stated verbatim by the operator; they are extracted from the cartridge's mandatory-field vocabulary (REF-02) and this session's own prose. Flagged for review, not asserted as final.

## 7. Generation-safety rules
Unchanged: 200-attempt retry cap, `WARN` at 50, fallback pool, never an infinite loop, never a silently short batch. Seed logged for audit only; **resolved parameters are what's persisted and graded against, never the seed re-evaluated later**.

## 8. Cross-service contract discipline — **new this pass**

Because generation and validation are now two independent codebases (not two modules in one binary), the shared vocabulary in §6 above is the **only** thing allowed to drift between them undetected if it isn't centralized. Rule: neither `taskgen` nor `grader` hardcodes any enum from §6 as a Go string literal in application logic — both import the generated types from the `schema` module (see ADR-006, ADR-007). A reason code, verdict, or validation-method string that exists in one service's code but not in the `schema` module is a build-time error, not a runtime surprise.
