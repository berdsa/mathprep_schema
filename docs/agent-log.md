# Agent log

## 2026-09-21 — Phase 3 resumed with G1-NUM-011

- Added the canonical `G1-NUM-011` addition-within-20 specification to `07-task-type-specs-exemplars.md`; taskgen implemented and verified the corresponding generator.

## 2026-09-21 — Phase 3 G1-NUM-012

- Added the canonical missing-subtrahend specification to `07-task-type-specs-exemplars.md`.

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

## 2026-09-20 — Shared Go module root correction

- Moved `pkg/core/go.mod` and `pkg/core/go.sum` to the repository root; the module declaration remains `github.com/berdsa/mathprep_schema`.
- Updated validation package imports to the actual sub-package path `github.com/berdsa/mathprep_schema/pkg/core`; no Go source files were moved.
- `GOROOT=/usr/local/go GOTOOLCHAIN=local go mod tidy` and `go test ./...` pass from the repository root.
- A throwaway external smoke package imported `github.com/berdsa/mathprep_schema/pkg/core` and referenced `core.VerdictCorrect` successfully against the working tree.

## 2026-09-20 — One-time generic grader dispatch

- Added `validation.Validate(method, raw, correct)` as the shared dispatch entry point.
- The grader submission handler now reads `task_type.validation_method` and dispatches through the shared pipeline instead of assuming `EXACT-INT`.
- Existing EXACT-INT behavior remains covered by the package tests.

## 2026-09-20 — BOOL shared validator

- Added the catalog BOOL validator with the declared fixed comparison vocabulary and case-insensitive synonym normalization.

## 2026-09-20 — CANON list validator

- Added canonical numeric-list sorting and comparison for the ordering task family.
## 2026-09-20 — G3-NUM-002

- Appended the canonical full field-table specification for multiplication facts, with exact factor bounds, shared EXACT-INT input contract, instance-space count, worked examples, and misconception tags.

## 2026-09-20 — G3-NUM-003

- Appended the canonical full field-table specification for exact division, including constructed divisibility, exact finite instance space, shared EXACT-INT contract, worked examples, and misconception tags.

## 2026-09-20 — G3-NUM-004

- Appended the canonical full field-table specification for combined three-digit addition/subtraction with explicit carry/borrow constraints.

## 2026-09-20 — G3-NUM-006

- Appended the canonical full field-table specification for integer order-of-operations expressions with exact division.

## 2026-09-20 — G3-NUM-007

- Appended the canonical full field-table specification for nearest-ten and nearest-hundred rounding with half-up ties.

## 2026-09-20 — G3-NUM-008

- Appended the canonical full field-table specification for exact unit-fraction quantities.

## 2026-09-20 — G3-NUM-009

- Appended the canonical full field-table specification for rectangle/square perimeter.

## 2026-09-20 — TUPLE validator

- Added the convention-defined ordered tuple parser/normalizer and generic pipeline dispatch for `TUPLE`; the schema version is now `v0.2.5`.

## 2026-09-20 — G3-NUM-011

- Appended the canonical full field-table specification for division with remainder using the convention-defined ordered TUPLE validator.

## 2026-09-20 — G3-NUM-010

- Appended the canonical full field-table specification for rectangle/square area.
## 2026-09-20 — EXACT-RAT shared validation

- Added the shared EXACT-RAT parse/normalize/compare/verdict dispatcher path, including lowest-terms enforcement and canonical integer output.
- Added unit coverage for correct, unreduced, mismatched, and zero-denominator answers.

## 2026-09-20 — G6-FRA-004 specification

- Added the canonical full-field specification for fraction multiplication/division, including reduced EXACT-RAT answers and worked examples.

## 2026-09-20 — G6-DEC-001 specification

- Added the canonical full-field decimal-arithmetic specification with TOL validation and independent-operation examples.
## 2026-09-20 — G6-PCT-001 specification

- Added the canonical full-field specification for percentage-of-a-number tasks.
- Reuses the shared EXACT-RAT validator; no schema implementation change is required.

## 2026-09-20 — G6-PCT-002 specification

- Added the canonical full-field specification for percentage-change tasks.
- Reuses the shared TOL validator; no schema implementation change is required.

## 2026-09-20 — G6-RAT-001 preparation

- Added the canonical ratio-simplification specification and shared CANON ratio validator support.

## 2026-09-20 — G6-RP-001 specification

- Added the canonical full-field specification for one-variable proportion solving.
- Reuses the shared EXACT-RAT validator; no schema implementation change is required.

## 2026-09-20 — G6-NS-001 specification

- Added the canonical full-field specification for GCD/LCM tasks.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G6-NS-002 specification

- Added the canonical full-field specification for negative-number arithmetic.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G7-GEO-002 specification

- Added the canonical full-field specification for similar-triangle scale-factor tasks.
- Reuses the shared TOL validator; no schema implementation change is required.

## 2026-09-20 — G7-GEO-003 specification

- Added the canonical full-field specification for circle circumference and area tasks.
- Reuses the shared TOL validator; no schema implementation change is required.

## 2026-09-20 — G7-GEO-004 specification

- Added the canonical full-field specification for special-angle trigonometric ratios.
- Reuses the shared TOL validator; no schema implementation change is required.

## 2026-09-20 — G7-SP-001 specification

- Added the canonical full-field specification for permutation and combination tasks.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G7-SP-002 specification

- Added the canonical full-field specification for compound probability tasks.
- Reuses the shared EXACT-RAT validator; no schema implementation change is required.

## 2026-09-20 — G7-SP-003 specification

- Added the canonical full-field specification for measures of center and spread.
- Reuses the shared TOL validator; no schema implementation change is required.

## 2026-09-20 — G7-F-001 specification

- Added the canonical full-field specification for polynomial function evaluation.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G7-F-002 specification

- Added the canonical full-field specification for rational-function domain checks.
- Reuses the shared SET validator; no schema implementation change is required.

## 2026-09-20 — G7-NS-001 specification

- Added the canonical full-field specification for prime factorization.
- Reuses the shared CANON list validator; no schema implementation change is required.

## 2026-09-20 — G7-NS-002 specification

- Added the canonical full-field specification for divisibility checks.
- Reuses the shared BOOL validator; no schema implementation change is required.

## 2026-09-20 — G10-TRG-001 specification

- Added the canonical full-field specification for special-value sine equations.
- Reuses the shared SET validator; no schema implementation change is required.

## 2026-09-20 — G10-LOG-001 specification

- Added the canonical full-field specification for clean logarithmic equations.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G10-EXP-001 specification

- Added the canonical full-field specification for clean exponential equations.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G10-SEQ-001 specification

- Added the canonical full-field specification for arithmetic sequence terms and sums.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G10-SEQ-002 specification

- Added the canonical full-field specification for geometric sequence terms and finite sums.
- Reuses the shared EXACT-INT validator; no schema implementation change is required.

## 2026-09-20 — G10-TRG-001 notation correction

- Clarified that answers are integer multiples of π/12 so the shared integer SET validator can enforce the canonical angle set.

## 2026-09-20 — task type reconciliation grant

- Added migration `000006_taskgen_task_type_reconciliation` so the taskgen service role can insert and update its registered `task_type` rows at startup. Its existing `SELECT` grant remains in place.
- Local database also needed the already committed `000005_task_type_grade_band` migration before University rows could be stored.

## 2026-09-21 — catalog relabel and shared validators

- Added the transactional `000007_task_type_catalog_relabel` migration, including foreign-key-safe relabeling of existing task instances and a reverse migration with legacy-domain restoration.
- Extended the shared validation pipeline with element-wise MATRIX comparison, numeric-array TOL comparison, and scalar support for the existing TUPLE method; added focused tests.

## 2026-09-21 — G1-NUM-013 canonical spec

- Added the canonical G1 missing-minuend specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-014 canonical spec

- Added the canonical G1 three-addend specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-015 canonical spec

- Added the canonical G1 expression-comparison specification; taskgen implements the generator and reuses the existing BOOL validator.

## 2026-09-21 — G1-NUM-016 canonical spec

- Added the canonical G1 addition-result word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-017 canonical spec

- Added the canonical G1 addition-change word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-018 canonical spec

- Added the canonical G1 addition-start word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.
