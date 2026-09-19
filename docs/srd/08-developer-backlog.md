# 08 — Developer Backlog

For a senior Go developer implementing `mathprep-schema`, `mathprep-taskgen`, and `mathprep-grader` as three independent git repositories (ADR-006), integrated only through a shared PostgreSQL schema (ADR-006, ADR-007). Ordering follows the operator's explicit instruction: **DB and dictionaries first → one task type end to end → multi-stage confirmation → repeat one type at a time, grade 1 through university → journal from day one, analytics as its own later phase.**

Every phase below ends with an explicit **Exit criteria** list. Do not start the next phase until the current one's exit criteria are met and Stage D (§Confirmation Gate) sign-off is given, where the gate applies.

---

## Phase 0 — Schema, tables, dictionaries (`mathprep-schema` repo)

**Scope:**
1. Repository skeleton: `mathprep-schema`, Go module, migration tool of the developer's choice (e.g. `golang-migrate` or `goose` — either is a reasonable, standard fit for this stack; not mandated further, developer's judgment) `[ASSUMPTION]`.
2. DDL for every table in `03-architecture.md`'s ERD: `USERS`, `STUDENTS`, `GENERATION_REQUEST`, `TASK_TYPE`, `TASK_SET`, `TASK_INSTANCE`, `SUBMISSION`, `MASTERY_TOPIC`, `EVENT_LOG`.
3. Dictionary tables (or `CHECK`/enum constraints — developer's call) for every row in `00-conventions.md` §6: `domain`, `grade_band`, `tier_code`, `validation_method`, `equivalence_policy`, `generation_mode`, `task_type_status`, `verdict`, `reason_code`, `render_target`, `locale`, `user_type`. Seed each with its stated values.
4. Idempotency constraints, exactly as specified in `03-architecture.md`: `UNIQUE(student_id, idempotency_key)` on `GENERATION_REQUEST` and `TASK_SET`; `UNIQUE(item_id, student_id, idempotency_key)` on `SUBMISSION`.
5. `EVENT_LOG`'s dedicated database role: `INSERT`-only grant, no `UPDATE`/`DELETE` — create this role now, even though nothing writes to it yet, so the privilege boundary exists from the first commit rather than being bolted on later.
6. Per-service DB roles: a `taskgen_svc` role (write on `GENERATION_REQUEST`/`TASK_SET`/`TASK_INSTANCE`, read on `TASK_TYPE`/`MASTERY_TOPIC`, insert-only on `EVENT_LOG`) and a `grader_svc` role (write on `SUBMISSION`/`MASTERY_TOPIC`, **read-only** on `TASK_INSTANCE`, insert-only on `EVENT_LOG`). Grader must not be able to write `TASK_INSTANCE` — see `04-nfr-risk-ops.md` STRIDE table.
7. The shared Go module surface: exported constants for every dictionary in §6 of `00-conventions.md`, row structs matching the ERD, and the `parse → normalize → compare → verdict` validation-pipeline package (empty/stubbed per-type logic for now — Phase 1 fills in the first real validator).
8. Golden-test scaffold directory convention (`testdata/golden/<TypeID>.json`) — the directory structure and JSON shape, no fixtures yet.

**Exit criteria:**
- Migrations run clean against a fresh local Postgres instance.
- All dictionary tables seeded, queryable, and match `00-conventions.md` §6 exactly (no typos, no missing values).
- Both service DB roles exist and their grants have been manually verified (attempt a forbidden write from each role and confirm it is rejected).
- `mathprep-schema` tagged `v0.1.0`, published so the next two repos can `go get` it.

---

## Phase 1 — One task type, end to end (`mathprep-taskgen` + `mathprep-grader` repos, first commits)

**Chosen type: `G3-NUM-001`** (simplest validation method, `EXACT-INT`, no tuple/rational complexity — the right first case to prove the pattern, not the hardest one).

**`mathprep-taskgen`:**
1. Repository skeleton, imports `mathprep-schema v0.1.0`.
2. Generator registry (`map[string]Generator`), boot-time duplicate-key panic check, build-time allowlist so only `FINAL`/`GATED` types load (empty for now except `G3-NUM-001` once it's GATED).
3. `Generate()` implementation for `G3-NUM-001` exactly per `07-task-type-specs-exemplars.md`: variable ranges, reject-and-retry for ≥1 carry, 200-attempt cap with `WARN` at 50.
4. `GENERATION_REQUEST` table: `POST /v1/generation-requests` handler (insert row, check idempotency first) + `GET /v1/generation-requests/:id` + the worker goroutine (`SELECT ... FOR UPDATE SKIP LOCKED`, lease/heartbeat, write `TASK_SET`+`TASK_INSTANCE`+`EVENT_LOG` in one transaction).
5. Webhook-style auth stub for the bot boundary (real Telegram signature check can follow; a placeholder shared-secret header is acceptable for this phase, documented as such).

**`mathprep-grader`:**
1. Repository skeleton, imports `mathprep-schema v0.1.0`.
2. Fill in the `EXACT-INT` branch of the shared validation-pipeline package (this is the first real logic in that package — everything else stays a documented stub until its type is reached).
3. `POST /v1/items/:id/submissions` handler: parse → normalize → compare → verdict → write `SUBMISSION`+`EVENT_LOG` in one transaction → incrementally update `MASTERY_TOPIC` (this is core, not deferred analytics — see `02-requirements.md` FR-008's closing note).
4. QR-token verification stub (real signing scheme can follow; document the placeholder).

**Verification (both repos):**
- Verification oracle: generate 1000 instances of `G3-NUM-001`, independently recompute each via a second code path (stdlib big-int), assert equality and non-degeneracy (≥1 carry present). Zero failures required.
- Golden tests: ≥20 fixed-seed cases per `00-conventions.md` §golden-test convention, covering `CORRECT`/`INCORRECT`/`UNPARSEABLE`/boundary.
- Manual QA: the operator (or a reviewer) solves 10 freshly generated instances "blind" and confirms every one is correct and the rendered `ru-KZ` text reads naturally.

**Exit criteria:**
- 1000/1000 oracle pass, golden tests green, manual QA complete, `G3-NUM-001` marked `GATED` in `TASK_TYPE`.

---

## Confirmation Gate (applies before every subsequent type, not just this first one)

This is the "several stages" the operator asked for, made concrete rather than left implicit:

| Stage | What it checks | Who |
|---|---|---|
| A — Automated | Oracle 1000/1000 (both tiers if the type has T1/T2), golden tests green in CI | CI, no human needed |
| B — Code review | The shared validation-pipeline package was actually extended and reused — not a type-specific one-off hack; the input-contract regex matches the spec's grammar exactly, character for character | A second reviewer, or the same developer against a written checklist if no second reviewer exists |
| C — Content review | The rendered problem text, in `ru-KZ`, reads naturally at the stated grade level; worked examples in the spec are re-verified by hand | Operator |
| D — Explicit go/no-go | Written approval to proceed to the next type. **Silence is not approval** — the developer waits for an explicit yes before starting the next type's Phase-2-style work | Operator |

Only after Stage D does work on the next type begin. This gate repeats for every single type from here through the end of the university wave — it is not a one-time bar cleared after `G3-NUM-001`.

---

## Phase 2+ — Remaining types, one at a time, curriculum order

Order, per `math-task-catalog.md`'s own grouping: **Grade 1–2 → Grade 3–4 (remainder) → Grade 5–6 (remainder) → Grade 7–9 → Grade 10–11 → University.** Within each grade band, no particular column order is mandated — pick the next type, spec it fully per the `07-task-type-specs-exemplars.md` field template, implement, run it through the full Confirmation Gate, get Stage D, move to the next.

**Hard, non-negotiable insertion point:** before any Grade 10–11 CAS-adjacent type (derivatives, integrals, tangent lines, extrema) or any University type is started, the **CAS security boundary** (`OPEN-06`, `backend-integration.md` §3) must be built as its own service (`mathprep-cas`, a fourth repository, added to the registry in `00-index.md` only when this phase starts) and pass its own sign-off: whitelist-grammar tokenization, no `eval()`, AST node-count/depth caps, separate process with CPU/memory/wall-clock limits and a hard kill, per-session rate limit, and a golden DoS test suite (including pathological inputs like deeply nested exponentiation). This is a direct, named consequence of `SCOPE-AMD-01` — flagged again here so it isn't missed at the point it actually becomes blocking, weeks or months into the rollout.

Curriculum verification (`OPEN-01`, `MISS-01`) is still needed before any type moves from `GATED` to `FINAL` — types may stay `GATED` and be used in the family pilot (`ASM-08`) indefinitely without blocking on this, but none should be marked `FINAL` (i.e., considered reconciled and stable) until the curriculum reference is actually supplied.

**Exit criteria for Phase 2+ as a whole:** every task type in `math-task-catalog.md` (excluding the explicitly out-of-scope categories: graph plotting, geometric construction, open-ended proofs — `00-scope-lock.md` §3) has reached at least `GATED` status, or has an explicitly logged reason it hasn't (e.g., blocked on `OPEN-06`, blocked on a genuinely unresolvable multiple-valid-answer form per the cartridge's own exclusion rule).

---

## Deferred phase — Analytics (`mathprep-analytics` repo, started only after the above is substantially stable)

Per the operator's explicit phasing: this starts **after** main functionality is complete, not in parallel with it. `[ASSUMPTION]` — "complete" is interpreted here as: Phase 1 is done, the Confirmation Gate pattern is proven, and a meaningful working subset of types is live and in daily family use — not literally every single type through university, since that could take a very long time and there's no reason analytics should wait that long. If the operator meant literally "after the entire catalog is done," say so and this trigger point moves.

**Scope, when started:**
1. New repo, read-only DB role on `EVENT_LOG` (per `04-nfr-risk-ops.md`).
2. Rollup job (batch, run on a schedule — a `cron`-style trigger is enough at this scale, no need for anything fancier) computing empirical p-value and discrimination index per type/tier from `EVENT_LOG` + `SUBMISSION` history.
3. A new `mathprep-schema` migration for whatever rollup table this needs — owned by `mathprep-schema`, not by `mathprep-analytics` itself (§1 of `backend-integration.md`).
4. Surfacing the `OPEN-04` divergence threshold as an actual configurable value once there's real data to calibrate it against — do not guess a number before data exists.

**Explicitly NOT part of this deferred phase, restated because it's the easiest thing to misread:** `MASTERY_TOPIC`'s incremental EMA update is core functionality, already built in Phase 1/2 inside `mathprep-grader`. It does not wait for this phase.

---

## Cross-cutting notes for the developer, gathered from every chapter's fine print

- Never hardcode a dictionary value (verdict, reason code, domain, etc.) as a raw string literal in `mathprep-taskgen` or `mathprep-grader` application code — import it from `mathprep-schema`. A string literal duplicating a dictionary value is a code-review rejection under Stage B above.
- `UNPARSEABLE` never increments `attempt_index`, never touches `MASTERY_TOPIC`. This is tested explicitly in every type's golden-test set, not assumed.
- The correct answer for an already-issued `TASK_INSTANCE` is never recomputed from its `seed` at grading time — always read `correct_answer_json` as frozen at issuance (ADR-003). A generator code change must never retroactively change what "correct" meant for an instance already shown to a student.
- `EVENT_LOG` writes happen in the same transaction as the business write they describe — never as an async afterthought, never with `raw_input` copied into the payload (see `data-governance.md`'s minimization note — that would defeat the 90-day `raw_input` retention policy through an indefinitely-retained duplicate).
- The 200-attempt generation retry cap and the `WARN` at 50 are per-call, logged, and never silently swallowed — a type that can't be generated within the cap falls back to its declared fallback pool, and if that's also exhausted, it's dropped from the current batch with a logged reason, never a silently short batch.
