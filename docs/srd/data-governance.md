# Data Governance

## Data inventory & classification — updated for USERS/STUDENTS split

| Field | Classification | Note |
|---|---|---|
| `USERS.user_id` | pseudonymous identifier | low sensitivity alone |
| `USERS.user_type` | low sensitivity | dictionary value, not personal in itself |
| Telegram↔user_id mapping | personal data of a minor (for `STUDENT`-type users) | high sensitivity — kept in a separate, more restricted table/role than analytics |
| `STUDENTS.grade` | personal data | low-moderate |
| `SUBMISSION.raw_input` | minor's education-performance data | moderate — minimized, see below |
| `MASTERY_TOPIC` scores | inferred proficiency data of a minor | moderate |
| `EVENT_LOG.payload_json` | mixed — may echo submission/generation details | classified the same as the field it echoes; **must not embed raw Telegram identity, only the pseudonymous `student_id`** |
| — | No health, financial, or biometric data collected | out-of-scope data class |

## Lawful basis and consent
Unchanged: `ASM-08` — family-only pilot, operator is the legal guardian of the data subjects. Does not extend to `client-access-expansion`; `OPEN-02`'s fail-closed gate stands there.

## Minimization & retention
Unchanged in substance: `raw_input` 90 days then redacted to verdict+reason_code only; `seed`+`params_json` retained indefinitely (reproducibility, CON-05); `SUBMISSION` verdict/reason/attempt indefinite, append-only; `TASK_SET`/`TASK_INSTANCE` indefinite; `MASTERY_TOPIC` current EMA only.

**New this pass:** `EVENT_LOG` retention is **indefinite by design** (FR-008's entire purpose is a complete history for later analytics) — this is a deliberate exception to the 90-day `raw_input` policy above, so the two must not be confused: `EVENT_LOG.payload_json` for a `SUBMISSION_GRADED` event should carry the verdict and reason_code, **not a copy of `raw_input`** — otherwise the 90-day minimization on `SUBMISSION.raw_input` is silently defeated by an indefinitely-retained duplicate in the journal. `[DERIVED]` — this is a genuine minimization requirement the new journal introduces; flagging it now rather than letting the developer discover it as a compliance gap later.

## Residency & sub-processors
Unchanged: existing VPS, `ASM-09`. **HYBRID-AI sub-processor note (G4-NUM-005)** unchanged from prior pass — operand values and template slots only, never `student_id` or `raw_input`, per ADR-005.

**New role added this pass:** `analytics`, when built, gets a read-only DB role scoped to `EVENT_LOG` and its own derived tables — it is never granted access to `USERS`, the identity-mapping table, or `SUBMISSION.raw_input`, since none of its stated purposes (empirical difficulty, discrimination, drift) require raw identity or raw input text.

## Deletion / export
Unchanged: no self-service UI in this backlog's scope; manual admin action against `user_id`; export is a JSON dump per student across `TASK_SET`/`TASK_INSTANCE`/`SUBMISSION`/`MASTERY_TOPIC`. **Extended this pass:** an export must also either include or explicitly account for that student's `EVENT_LOG` rows — an export that silently omits journal history is incomplete, not just minimal.
