# 02 — Requirements

FR-001 through FR-006 are carried forward from the prior pass with two textual updates applied throughout: (a) `STUDENT` references now mean the `STUDENTS` row joined to a `USERS` row of `user_type=STUDENT` (finding G, see `03-architecture.md` ERD); (b) "the bot requests a set" now means "the bot inserts a `GENERATION_REQUEST` row" — the synchronous-looking Gherkin `Given/When/Then` wording is preserved because it still describes observable behavior correctly (the request is accepted, processed, and answered), just now via a queue rather than in-handler computation. Two requirements are added.

## FR-001 — Generate a daily task set with adaptive topic weighting
*(unchanged from prior pass — see original Gherkin: happy path with weak-topic over-representation, no-mastery-history boundary, requested-count-exceeds-variety boundary, unregistered-grade-band failure)*

## FR-002 — Validate a submitted answer and return a verdict
*(unchanged — happy path, leading zero, whitespace, oversized-payload abuse case)*

## FR-003 — Idempotent resubmission
*(unchanged — exact retry, same-key-different-item, concurrent duplicate, missing-key failure)*

## FR-004 — UNPARSEABLE never affects mastery or attempt counters
*(unchanged — incomplete tuple, correct resubmission counts as attempt 1, CAS-timeout forward contract, repeated-empty-submission abuse case)*

## FR-005 — Defect-triggered invalidation and re-grade, snapshot preserved
*(unchanged — happy path, mastery rollup recompute, precise blast-radius boundary, duplicate-remediation-trigger idempotency)*

## FR-006 — Fallback-pool exhaustion never silently shrinks a batch
*(unchanged — declared |S|=1 exception honored, near-exhaustion metric, whole-domain-exhausted degradation, oversized-count-request abuse case)*

## FR-007 — Generation is mediated by a durable job queue, not an in-request call *(new)*

As `taskgen`, I want incoming generation requests recorded as rows before any work starts, so that a crash mid-generation never loses the request and never double-processes it.

```gherkin
Scenario: Happy path — request accepted, processed, polled to completion
  Given the bot submits a generation request for student S, grade 3, count 10
  When taskgen's HTTP handler receives it
  Then a GENERATION_REQUEST row is inserted with status=PENDING and a request_id is returned with 202 Accepted
  And a background worker within the same service picks it up via SELECT ... FOR UPDATE SKIP LOCKED
  And on completion the row's status becomes DONE and TASK_SET/TASK_INSTANCE rows exist

Scenario: Boundary — worker crashes mid-batch
  Given a GENERATION_REQUEST row is marked IN_PROGRESS by worker instance W1
  When W1 crashes before marking it DONE
  Then a lease/heartbeat timeout returns the row to PENDING so another worker instance can pick it up
  And no partial TASK_INSTANCE rows from the crashed attempt are left in a visible state (single transaction per instance write)

Scenario: Boundary — duplicate request with the same idempotency key
  Given a GENERATION_REQUEST with idempotency_key K already exists in any status
  When a second request with the same (student_id, idempotency_key) arrives
  Then the original request_id and its current status are returned; no second row is inserted

Scenario: Failure — polling client asks about a request from another student
  Given request_id R belongs to student S1
  When a client authorized only for student S2 polls GET /v1/generation-requests/R
  Then the service returns 403, not the request's contents
```

## FR-008 — Every service call appends to an immutable event journal *(new)*

As the system, I want every generation, assignment, submission, and verdict event appended to `EVENT_LOG` at the moment it happens, so that the analytics layer built later (deliberately, in a separate later phase — see `08-developer-backlog.md`) has a complete history rather than a partial one reconstructed after the fact.

```gherkin
Scenario: Happy path — generation event logged
  Given a generation request completes successfully
  When the TASK_SET/TASK_INSTANCE rows are committed
  Then an EVENT_LOG row {event_type=GENERATION_COMPLETED, occurred_at, payload_json} is appended in the same transaction

Scenario: Happy path — submission event logged
  Given a student's answer is graded
  When the SUBMISSION row is committed
  Then an EVENT_LOG row {event_type=SUBMISSION_GRADED, ...} is appended in the same transaction

Scenario: Boundary — journal write failure does not silently drop the business event
  Given the EVENT_LOG insert fails for any reason
  When this happens inside the same transaction as the business write
  Then the whole transaction rolls back — a business event with no corresponding journal entry must never exist

Scenario: Failure/abuse — journal is never mutated after the fact
  Given an EVENT_LOG row exists
  When any process attempts an UPDATE or DELETE against EVENT_LOG
  Then this is rejected at the database role level (EVENT_LOG's write role has INSERT-only privilege)
```

**Explicitly out of FR-008's scope:** computing rollups, p-values, discrimination indices, or mastery drift from `EVENT_LOG`. That consumption is `analytics`, a separate later-phase deliverable per the operator's own phasing instruction — not blocked by, and not blocking, FR-008 itself. `MASTERY_TOPIC.ema_score` (needed by FR-001) is updated incrementally by `grader` directly off each `SUBMISSION`, not by the deferred analytics service — this distinction matters and is restated in `08-developer-backlog.md`.

## Non-functional requirements
Unchanged from prior pass (NFR-001…007) with NFR-004 now read as "per type **and per service that owns it**" and NFR-007 (`raw_input` retention) unchanged. No new NFRs this pass; CAS-specific NFRs (evaluator timeout budget, sandboxing overhead) are deferred to whichever pass first specs a CAS-bearing type, per `00-scope-lock.md`'s SCOPE-AMD-01 note.
