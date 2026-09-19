# 04 — NFR, Risk, Ops

## Performance & availability
NFR thresholds unchanged, see `02-requirements.md`. Degradation behavior, updated for the split: if `mathprep-taskgen` is down, `mathprep-grader` is unaffected (no runtime dependency between them) — students can still submit and get graded on already-issued items, they just can't receive a new set until `mathprep-taskgen` recovers. If `mathprep-grader` is down, already-generated items simply can't be answered yet; nothing is lost, since submissions are client-initiated and the QR page can retry.

## Observability
Structured JSON log per call: `request_id, student_id_pseudo, type_id, spec_version, verdict|null, latency_ms, retry_count, service_name` (new field — with two-then-three independent binaries, every log line must self-identify which service emitted it).

| Metric | Type | Alert condition | Owner |
|---|---|---|---|
| `generation_latency_ms` | histogram | p95 > NFR-002 for 2 consecutive days | backend — taskgen |
| `submission_latency_ms` | histogram | p95 > NFR-003 for 2 consecutive days | backend — grader |
| `generation_request_lease_expired_total` | counter | any increment (new — detects crashed/stuck workers under the job-queue model) | backend — taskgen |
| `retry_count_total{type_id}` | counter | any type at > 150 of the 200 retry cap | backend — taskgen |
| `fallback_pool_used_total{type_id}` | counter | any increment in 24h | methodologist |
| `unparseable_rate{type_id}` | gauge | > 15% over 7 days (NFR-005) | methodologist |
| `event_log_write_failures_total` | counter | any increment (should be structurally impossible per FR-008 — a non-zero value means the same-transaction guarantee was violated somewhere) | backend |

## Security — STRIDE per trust boundary (updated for 3 services)

| Boundary | Key mitigations |
|---|---|
| Bot ↔ mathprep-taskgen | Webhook signature/secret verification (spoofing); TLS + idempotency key (tampering); per-update-id logging (repudiation); per-chat rate limit (DoS) |
| QR Web ↔ mathprep-grader | Signed, time-boxed, single-item-scoped token, no raw bearer stored; server re-derives item context from the token; non-sequential UUIDv4 item_id `[ASSUMPTION]`; per-token attempt cap; `raw_input` max-length enforced pre-parse |
| mathprep-taskgen ↔ PostgreSQL | Parametrized queries only; statement timeout; DB role scoped to only the tables it needs (`GENERATION_REQUEST`, `TASK_SET`, `TASK_INSTANCE`, `TASK_TYPE` read, `EVENT_LOG` insert-only, `MASTERY_TOPIC` read) |
| mathprep-grader ↔ PostgreSQL | Parametrized queries only; statement timeout; DB role scoped separately (`SUBMISSION` write, `TASK_INSTANCE` read-only — **grader must never be able to write `TASK_INSTANCE`**, that would let a compromised grader forge what a student was shown; `EVENT_LOG` insert-only; `MASTERY_TOPIC` read+write) |
| mathprep-taskgen ↔ mathprep-grader | **No boundary exists** — they never talk to each other directly, by design (ADR-006). The only shared surface is the database, already covered above |
| mathprep-analytics ↔ PostgreSQL *(later phase)* | Read-only role on `EVENT_LOG` and derived tables only — never write access to any operational table |

**New row this pass, driven by the service split:** because `mathprep-taskgen` and `mathprep-grader` are separate deployables with separate DB roles, a compromise of one no longer automatically implies write access to the other's tables — this is a genuine security improvement of ADR-006 over the old single-role monolith, worth naming as a benefit, not just a cost.

## RAID register
RISK-001 through RISK-004 carried forward unchanged. New:

| ID | Risk | L×I | Mitigation | Residual | Owner |
|---|---|---|---|---|---|
| RISK-005 | `mathprep-schema` module version drifts between `mathprep-taskgen` and `mathprep-grader` (one upgrades, the other doesn't) | MED×MED | CI in each consuming service pins and checks the `mathprep-schema` version; a mismatch beyond a documented compatibility window fails the build | LOW | backend |
| RISK-006 | CAS boundary (`OPEN-06`) is rushed to unblock university types now that SCOPE-AMD-01 put them on the visible backlog | MED×HIGH | `08-developer-backlog.md` makes CAS boundary sign-off an explicit, non-skippable gate before any CAS-type work starts — named cost, not hidden | MED (open until built) | backend |
| RISK-007 | Bot given direct DB write access instead of going through `mathprep-taskgen`'s HTTP API, for simplicity | LOW×HIGH | Not the current design (ASM-10) — named here so a future shortcut doesn't get taken silently | LOW | backend |

## Failure modes
Unchanged (`generator panics mid-batch`, `DB unavailable during submission`), with ownership reattributed: the first to `mathprep-taskgen`, the second to `mathprep-grader`.
