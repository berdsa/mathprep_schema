# Backend Integration

Rewritten this pass for three independent Go services (ADR-006). The prior pass's single-monolith generator-registry section is retained conceptually but now scoped to `taskgen` alone.

## 1. Repository split and what each one owns

| Repo | Owns | Does NOT own |
|---|---|---|
| `schema` | All DDL migrations; dictionary seed data; a small versioned Go module (`module github.com/<org>/schema`) exporting: dictionary enums as typed constants, DB row structs matching the ERD, the shared validation-pipeline package (parse→normalize→compare) and its `Verdict`/`ReasonCode` types | Any HTTP handler, any business logic, any generator implementation |
| `taskgen` | Generator registry, `Generate()` implementations per type, the job-queue worker, `POST /v1/generation-requests`, `GET /v1/generation-requests/:id` | Answer validation, `grader`'s endpoints |
| `grader` | `POST /v1/items/:id/submissions`, QR-token verification, invoking the shared validation-pipeline package from `schema`, `MASTERY_TOPIC` incremental updates | Any generation logic |
| `analytics` *(later phase — do not start early)* | Reads `EVENT_LOG` (read-only DB role), computes rollups, populates a rollup table `schema` will need a migration for **when this phase starts**, not before | Nothing generation- or grading-related |

Each of the first three imports `schema` as a Go module dependency (`go.mod require`), pinned to a tagged version. A schema/enum change is: (1) new tag on `schema`, (2) `go get -u` in the consuming service(s), (3) that service's own CI must pass before deploy. This is the disclosed, deliberate exception to "don't put code in one project" — `schema` carries no business logic, only the contract every other service would otherwise have to duplicate and risk drifting (the exact CANON/SET drift risk REF-02 itself warns about). `[ASSUMPTION: ASM-12]` — flagged for the operator to veto if a shared-module dependency is unwanted even in this narrow form; the alternative (each service hand-copies the enum list) reintroduces RISK-003-class drift and is not recommended.

## 2. Shared validation pipeline (lives in `schema`, imported by `grader`)
Unchanged in logic from the prior pass: `parse → normalize → compare → verdict + reason_code`, one package, every type routes through it. `UNPARSEABLE` never increments `attempt_index`, never updates `MASTERY_TOPIC` (FR-004).

## 3. CAS security boundary — implemented and signed off
The CAS evaluator is implemented as the independent `cas` service and consumes the versioned queue contract owned by `schema`; it is not folded into `grader` and there are no direct service-to-service calls. `OPEN-06` is **CLOSED**: Ken's approval is recorded in `taskgen/docs/signoffs/OPEN-06.md` (`approved_at: 2026-09-22T04:40:40Z`, `approved_by: Ken`). That sign-off names the reviewed CAS implementation commit `bed8739` and the initial queue-contract tag `schema@v0.3.6`; the current schema contract is maintained by the additive CAS migration and its subsequent schema releases.

The signed-off boundary covers whitelist-grammar parsing without `eval()`, AST node/depth caps, isolated evaluation with CPU/memory/wall-clock limits and hard kill, per-session rate limiting, DoS fixtures, timeout-to-`UNPARSEABLE` behavior, and atomic result/event persistence. The approval closes the shared infrastructure gate only: every CAS-backed task type still requires its own specification, tests, and Confirmation Gate before use. Older CAS handoff reports that say the schema contract is missing or approval is pending are historical snapshots superseded by the signed-off record above.

## 4. Golden tests
Unchanged: `testdata/golden/<TypeID>.json`, N≥20 fixed-seed cases per type including ≥1 each of `CORRECT`/`INCORRECT`/`UNPARSEABLE`/boundary. Lives in whichever service owns that type's generation or validation logic — generator-side fixtures in `taskgen`, validator-side fixtures in `grader`, since they're now separate codebases with separate CI pipelines.

## 5. API contracts

**`taskgen`**

`POST /v1/generation-requests`
```json
// request
{ "student_id": "uuid", "grade": 3, "topics": ["G3-NUM","G3-MEA"], "count": 10, "idempotency_key": "uuid" }
// 202 response
{ "request_id": "uuid", "status": "PENDING" }
```

`GET /v1/generation-requests/:id`
```json
// 200 response, once DONE
{ "request_id": "uuid", "status": "DONE", "task_set_id": "uuid",
  "items": [ { "item_id": "uuid", "type_id": "G4-NUM-001", "spec_version": "1.0.0",
               "tier": "T1", "locale": "ru-KZ", "render_target": "plaintext",
               "problem": "257 + 486 = ?" } ] }
```
Idempotency: `(student_id, idempotency_key)` — same pair within 24h returns the original `request_id`/status, no new row (FR-007). `count` capped server-side at ≤50 before any instance-space evaluation.

**`grader`**

`POST /v1/items/:id/submissions`
```json
// request
{ "student_id": "uuid", "raw_input": "743", "idempotency_key": "uuid" }
// 200 response
{ "verdict": "CORRECT", "reason_code": "OK", "correct_answer_display": "743", "attempt_index": 1 }
```
Idempotency scope: `(item_id, student_id, idempotency_key)`.

| Code | Meaning | Owning service |
|---|---|---|
| 202 | generation request accepted, not yet complete | taskgen |
| 400 VALIDATION_ERROR | malformed request | both |
| 403 | authenticated caller does not own this resource (finding, FR-007 Failure scenario) | both |
| 404 | not found | both |
| 409 ITEM_ALREADY_FINALIZED | no new submissions accepted | grader |
| 422 UNSUPPORTED_TYPE | `type_id`/`grade` not in this build's active registry | taskgen |
| 429 RATE_LIMITED | — | both |
| 500 INTERNAL | — | both |

Versioning: URI major version (`/v1/`) per service, independently — `taskgen` and `grader` can advance their own API versions without coordinating a joint release, since they share no runtime dependency, only the DB schema (which is itself versioned via `schema` tags, §1).

**Transport boundary decision — `[ASSUMPTION: ASM-10]`, this pass's finding F:**
The Bot and the QR Web page talk to `taskgen`/`grader` over thin HTTP APIs, not direct Postgres connections. This is a deliberate security-boundary choice, not an oversight left over from the old `app-api`: giving the Telegram-facing bot process direct write credentials to the shared schema would mean a lower-trust, internet-facing process holds database credentials capable of touching every student's data — the exact kind of privilege escalation the STRIDE table below is built to prevent. If the operator specifically wants the bot to write directly to Postgres (skipping HTTP entirely, to keep the stack even leaner), that is a real option worth naming explicitly rather than defaulting past — flagging it here for a decision rather than silently building around it.

**Bot webhook authentication (developer-facing detail, not previously concrete enough to implement from):** verify the Telegram webhook signature/secret token per Telegram's own webhook-secret mechanism before accepting a request as bot-originated; reject anything else at the edge before it reaches `POST /v1/generation-requests`. `[ASSUMPTION]` — exact header name/verification steps belong in `taskgen`'s own README once implemented; not fabricated here since it depends on which Telegram library the developer picks.

## 6. Event journal (FR-008) — write-side contract
Both `taskgen` and `grader` write to `EVENT_LOG` **in the same transaction** as their respective business writes — never as a fire-and-forget side call. Minimum `event_type` set for Phase 1: `GENERATION_REQUESTED, GENERATION_COMPLETED, GENERATION_FAILED, SUBMISSION_GRADED, MASTERY_UPDATED`. The DB role each service connects with has `INSERT`-only privilege on `EVENT_LOG` (no `UPDATE`/`DELETE`) — enforced at the database level, not just by code discipline.

**What is explicitly NOT built in this phase:** any consumer of `EVENT_LOG` beyond what already exists (nothing reads it yet). `analytics` is the eventual reader, and it is out of scope until `08-developer-backlog.md`'s Analytics phase begins.
