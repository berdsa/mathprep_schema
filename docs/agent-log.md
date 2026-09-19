# Agent log

## 2026-09-19 — Repository initialization

- Confirmed this is the canonical `mathprep-schema` repository and retained all thirteen SRD artifacts directly under `docs/srd/`.
- Replaced the misplaced `pkg/core` guidance with the repository-wide `AGENTS.md` template, consistent with ADR-007 and the SRD.
- Added this append-only agent log.
- Checked Graphify usage; its current CLI requires `graphify update .` for the requested repository graph refresh.
- Local PostgreSQL initialization is pending: `POSTGRES_PASSWORD` was not present in the shell, so the documented container was not created and no credential was invented or stored.

## 2026-09-19 — Phase 0 migration plan

- Planned additive migration order: (1) create the 12 dictionary lookup tables and all nine ERD tables with keys, foreign keys, and ERD-derived status checks; (2) seed each dictionary value from `00-conventions.md` §6 exactly; (3) add only the three explicit idempotency unique constraints from `03-architecture.md`; (4) create the least-privilege `taskgen_svc` and `grader_svc` roles and grants.
- The ERD declares `grade` as an integer while the `grade_band` dictionary includes the textual value `UNIVERSITY`. The migrations retain the ERD integer column type and seed `UNIVERSITY` exactly; no undocumented coercion, extra grade column, or altered dictionary value is introduced.
- Verification plan: apply every migration to a fresh local PostgreSQL database; compare seeded dictionary values to §6; then `SET ROLE` to each service role and attempt its prohibited `TASK_INSTANCE` write, expecting PostgreSQL to reject both attempts.

## 2026-09-19 — Phase 0 base DDL

- Added the additive base migration for all 12 §6 lookup tables and all nine ERD tables, with primary keys, ERD relationships, dictionary foreign keys, and the stated generation-request status vocabulary.
- `task_type.locale` is included because `00-conventions.md` §6 explicitly names it as a locale dictionary consumer even though the abbreviated ERD field listing omits it.
- No explicit idempotency unique constraint is present yet; those are isolated in the next migration as planned.

## 2026-09-19 — Phase 0 dictionary seeds

- Seeded all values from `00-conventions.md` §6: 15 domains, 12 grade bands, 3 tiers, 9 validation methods, 3 equivalence policies, 2 generation modes, 3 task-type statuses, 3 verdicts, 10 reason codes, 2 render targets, 1 locale, and 3 user types.
- Reserved values (`latex`, `html-mathml`, and `kk-KZ`) were intentionally not seeded, as required by §6.

## 2026-09-19 — Phase 0 idempotency constraints

- Added exactly the three architecture-mandated unique constraints: `(student_id, idempotency_key)` on `generation_request` and `task_set`, and `(item_id, student_id, idempotency_key)` on `submission`.

## 2026-09-19 — Phase 0 service roles and grants

- Created `taskgen_svc` and `grader_svc` as non-login, non-superuser, non-creator roles; deployment-specific login credentials remain outside the repository.
- Granted taskgen DML on `generation_request`, `task_set`, and `task_instance`; taskgen read on `task_type` and `mastery_topic`; grader DML on `submission` and `mastery_topic`; grader read-only on `task_instance`.
- Granted `INSERT` only on `event_log` to both roles, with broad privileges revoked before the scoped grants.

## 2026-09-19 — Phase 0 migration verification

- Applied migrations `000001` through `000004` to a fresh PostgreSQL 16 container with `ON_ERROR_STOP=1`; every statement completed successfully.
- Verified all nine ERD tables and twelve dictionary tables exist. Dictionary counts and values match §6, including omission of reserved values. Verified all three required unique constraints and service-role privilege shape (`event_log` insert true/update false; grader `task_instance` update false).

## 2026-09-19 — Phase 0 forbidden-write probes

- Under `SET ROLE taskgen_svc`, a manual `INSERT INTO submission` was rejected: `permission denied for table submission`.
- Under `SET ROLE grader_svc`, a manual `INSERT INTO task_instance` was rejected: `permission denied for table task_instance`.

## 2026-09-19 — Phase 0 summary

- Phase 0 database scope is complete: additive DDL for the ERD, exact §6 dictionary seeds, the three specified idempotency constraints, least-privilege service roles, clean fresh-Postgres migration verification, and rejected forbidden-write probes.
- Release checkpoint: `v0.1.0`. Phase boundary reached; Phase 1 work must wait for explicit go-ahead.

## 2026-09-20 — Phase 0 step 7, GitHub remote

- Confirmed the tracked `github` remote points to `https://github.com/berdsa/mathprep_schema.git` for both fetch and push; no remote change was needed.

## 2026-09-20 — Phase 0 step 7, shared Go module

- Added `pkg/core/go.mod` with module path `github.com/berdsa/mathprep_schema` and pinned the `google/uuid` dependency.
- Added typed constants for every seeded §6 dictionary value and ERD row structs for all nine ERD tables.
- Implemented the `EXACT-INT` parse → normalize → compare → verdict pipeline with the converged input contract and reason codes.
- Added CORRECT, INCORRECT, UNPARSEABLE, and boundary tests; package tests pass with the repository's Go 1.24.3 SDK.
- Commits: `90e8d80`, `11a09b6`, `d392c4a`, `ce48093`, `01129c4`.

## 2026-09-20 — TASK_TYPE grade-band correction

- Added additive migration `000005_task_type_grade_band` to convert `task_type.grade` from `INTEGER` to `TEXT` and add the foreign key to `grade_band(code)`.
- Updated `core.TaskType.Grade` from `int` to `GradeBand`; aligned the ERD documentation with the dictionary-backed text type.
- Applied migrations to a fresh isolated database in the local PostgreSQL 16 container. Verified `grade` is `text`, the FK exists, `UNIVERSITY` inserts successfully, and an invalid grade is rejected.
- `GOROOT=/usr/local/go GOTOOLCHAIN=local go test ./...` passes in `pkg/core`.
