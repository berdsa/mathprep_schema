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

## FR-009 — Guardian-provisioned student sign-in stays bound to the existing child

As a guardian, I want to set up sign-in for an existing child profile and verify the child's own phone, so the child can use a new device without creating a duplicate learner or borrowing the guardian's phone identity.

The Platform API creates a short-lived one-use intent only after checking the authenticated guardian relationship and applicable consent. Auth owns OTP delivery/challenge state in Redis and returns a success result bound to the same intent and device flow. Only then may the Platform API atomically set the existing child principal's credentials, insert that principal's verified `phone_identity`, and mark/scrub the intent. Failed, expired, replayed, or mismatched OTP/device flows create no account, membership, consent, or verified identity. See SCOPE-AMD-04 and `docs/student-access-phone-intent-contract.md`.

## FR-010 — Independently registered student can request an authorized family learning link

As a student with an independent, phone-verified account, I want to request a link to a family learning profile, so I can use my own account without the system guessing which child record is mine.

The student initiates a one-use, short-lived pairing code. A signed-in family owner consumes it while selecting an active child profile in that family; the same student later reviews and confirms the selected profile from their own active account. Both confirmations, live account/tenant checks, existing relationship and current learning consent are required before the link becomes active. The link is a separate auditable authorization relationship: it never merges accounts, copies phone identities, changes the child principal or learner ID, creates guardian status, or grants/refreshes consent. Reads and writes must scope linked students to the single linked child; siblings and other family records remain hidden. Revocation on either side or consent withdrawal immediately denies later access. Local implementation uses fictional data and the synthetic policy only in development. See SCOPE-AMD-05 and `docs/student-profile-linking-contract.md`.

## FR-011 — Independently registered student can create a private self-owned practice profile

As an independently registered student, I want to create a private learning profile in my own student tenant and begin local practice without a family link, so account registration is useful while family access remains a separate optional relationship.

The profile is a distinct self-owned profile kind, not a `platform_children` family child and not a guardian relationship. Creation is allowed only in explicitly configured development mode with synthetic data and an acknowledged, versioned local-preview notice. Acknowledgement is not consent, age verification, guardianship, or production authorization. No parent, learner, guardian, family tenant, consent, or school placement row is fabricated. The profile has one active owner `(student_principal_id, student_tenant_id)`, provisions the engine learner identity atomically, and can be read or used for learning only by that same active student membership and principal. Production profile creation and learning access fail closed until a separately reviewed legal and data-model policy authorizes them. Family-owned child access continues to require current guardian relationship, granted learning consent, and (for independently registered students) the existing two-party profile link. See `docs/student-self-profile-contract.md`.

## FR-012 — Legacy student proves a personal phone before trusted-device access

As a student whose existing account has no verified phone, I want to add and prove my own WhatsApp-capable phone after entering my existing credentials, so I can use my account on a new device without borrowing a guardian's identity or phone.

After password verification, Platform API creates a short-lived one-use intent bound to that active student principal, membership, and device. The intent stores no raw/unverified phone. Auth validates the student-entered E.164 destination against the live intent, sends a rate-limited WhatsApp-first OTP with an explicitly capped SMS fallback, and verifies the code against the exact destination. Only then may Platform API atomically create the verified phone identity, consume the intent, and issue trusted-device/session data. A failed, expired, replayed, mismatched, or inactive-membership flow creates no verified phone or session. Existing verified-phone OTP and trusted-device flows remain unchanged. A parent/teacher context switch cannot stand in for the student's own password or OTP proof; an unverified student must authenticate directly. See SCOPE-AMD-06 and `docs/student-phone-enrollment-contract.md`.
