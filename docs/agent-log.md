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

## 2026-09-21 — G1-NUM-019 canonical spec

- Added the canonical G1 subtraction-result word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-020 canonical spec

- Added the canonical G1 subtraction-change word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-021 canonical spec

- Added the canonical G1 subtraction-start word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-022 canonical spec

- Added the canonical G1 commutative-property specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-023 canonical spec

- Added the canonical G1 fact-family subtraction specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-024 canonical spec and BOOL extension

- Added the canonical G1 true/false equation specification and extended the shared BOOL validator with canonical TRUE/FALSE answers and focused coverage.

## 2026-09-21 — G1-NUM-025 canonical spec

- Added the canonical G1 multi-step addition/subtraction specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-NUM-026 canonical spec

- Added the canonical G1 no-borrow subtraction specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-MEA-001 canonical spec

- Added the canonical G1 length-addition specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-MEA-002 canonical spec

- Added the canonical G1 length-subtraction specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-MEA-003 canonical spec

- Added the canonical G1 length-comparison specification; taskgen implements the generator and reuses the existing BOOL validator.

## 2026-09-21 — G1-MEA-004 canonical spec

- Added the canonical G1 length-ordering specification; taskgen implements the generator and reuses the existing CANON validator.

## 2026-09-21 — G1-MEA-005 canonical spec

- Added the canonical G1 time-plus-hours specification using the catalog-permitted EXACT-INT-minutes output contract.

## 2026-09-21 — G1-MEA-006 canonical spec and clock validation

- Added the canonical G1 time-plus-half-hour specification and shared canonical H:MM validation, keeping clock times distinct from ratios.

## 2026-09-21 — G1-MEA-007 canonical spec

- Added the canonical G1 time-minus-half-hour specification; taskgen reuses the shared clock-time canonical validator.

## 2026-09-21 — G1-STA-001 canonical spec

- Added the canonical G1 three-category data-total specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-STA-002 canonical spec

- Added the canonical G1 data-difference specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-STA-003 canonical spec and BOOL labels

- Added the canonical G1 most-category specification and extended the shared BOOL validator with the fixed red/blue/green category vocabulary.

## 2026-09-21 — G1-MEA-008 canonical spec and BOOL units

- Added the canonical G1 length-unit selection specification and extended the shared BOOL validator with the fixed cm/kg/L vocabulary.

## 2026-09-21 — G1-MEA-009 canonical spec

- Added the canonical G1 true/false measurement-comparison specification; taskgen reuses the shared TRUE/FALSE BOOL validator.

## 2026-09-21 — G1-MEA-010 canonical spec

- Added the canonical G1 length-difference word-problem specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-STA-004 canonical spec

- Added the canonical G1 pet-count total specification; taskgen implements the generator and reuses the existing EXACT-INT validator.

## 2026-09-21 — G1-GEO-001 canonical spec and BOOL dimensions

- Added the canonical G1 2D/3D classification specification and extended the shared BOOL validator with the fixed 2D/3D vocabulary.

## 2026-09-21 — G1-GEO-002 canonical spec

- Added the canonical G1 half-fraction specification; taskgen implements the fixed generator and reuses the existing EXACT-RAT validator.

## 2026-09-21 — G1-GEO-003 canonical spec

- Added the canonical G1 fourth-fraction specification; taskgen implements the fixed generator and reuses the existing EXACT-RAT validator.

## 2026-09-21 — G1-GEO-004 canonical spec

- Added the canonical G1 shaded-fraction specification with two allowed denominators and one explicitly shaded part.

## 2026-09-21 — G1-GEO-005 canonical spec

- Added the canonical G1 equal-parts count specification with a fixed answer of four.

## 2026-09-21 — G1-GEO-006 canonical spec

- Added the canonical G1 triangle-side boolean specification.

## 2026-09-21 — G1-GEO-007 canonical spec

- Added the canonical G1 shape-side comparison specification and registered `square` in the shared BOOL vocabulary.

## 2026-09-21 — G1-GEO-008 canonical spec

- Resolved the catalog FLAG by adding the four-right-angles condition, making `square` the unique answer.

## 2026-09-21 — G1-GEO-009 canonical spec

- Added the canonical G1 total-sides specification for a triangle and square.

## 2026-09-21 — G2-NUM-010 canonical spec

- Added the canonical Grade 2 successor-number specification.

## 2026-09-21 — G2-NUM-011 canonical spec

- Added the canonical Grade 2 predecessor-number specification.

## 2026-09-21 — G2-NUM-012 canonical spec

- Added the canonical Grade 2 tens-digit specification.

## 2026-09-21 — G2-NUM-013 canonical spec

- Added the canonical Grade 2 ones-digit specification.

## 2026-09-21 — G2-NUM-014 canonical spec

- Added the canonical Grade 2 ordered place-value tuple specification.

## 2026-09-21 — G2-NUM-015 canonical spec

- Added the canonical Grade 2 tens-place-value specification.

## 2026-09-21 — G2-NUM-016 canonical spec

- Added the canonical Grade 2 ones-place-value specification.

## 2026-09-21 — G2-NUM-017 canonical spec

- Added the canonical Grade 2 two-digit comparison specification.

## 2026-09-21 — G2-NUM-018 canonical spec

- Added the canonical Grade 2 three-number ordering specification.

## 2026-09-21 — G2-NUM-019 canonical spec

- Added the canonical Grade 2 addition-with-multiple-of-ten specification.

## 2026-09-21 — G2-NUM-020 canonical spec

- Added the canonical Grade 2 subtraction-with-multiple-of-ten specification.

## 2026-09-21 — G2-NUM-021 canonical spec

- Added the canonical Grade 2 ten-more-than-number specification.

## 2026-09-21 — G2-NUM-022 canonical spec

- Added the canonical Grade 2 ten-less-than-number specification.

## 2026-09-21 — G2-NUM-023 canonical spec

- Added the canonical Grade 2 no-carry two-digit-plus-one-digit addition specification.

## 2026-09-21 — G2-NUM-024 canonical spec

- Added the canonical Grade 2 skip-count-by-tens specification with all shown terms and the step rendered.

## 2026-09-21 — G2-NUM-025 canonical spec

- Added the canonical Grade 2 skip-count-by-fives specification with all shown terms and the step rendered.

## 2026-09-21 — G2-NUM-026 canonical spec

- Added the canonical Grade 2 skip-count-by-twos specification with all shown terms and the step rendered.

## 2026-09-21 — G2-NUM-027 canonical spec

- Added the canonical Grade 2 place-value construction specification.

## 2026-09-21 — G2-NUM-028 canonical spec

- Added the canonical Grade 2 expanded-form conversion specification.

## 2026-09-21 — G2-NUM-029 canonical spec

- Added the canonical Grade 2 missing-middle sequence specification.

## 2026-09-21 — G2-NUM-030 canonical spec

- Added the canonical Grade 2 greater-of-two-numbers specification.
## 2026-09-21 — G2-GEO-011 canonical spec

- Resolved the catalog circle-side-count FLAG by restricting the shape set to five unambiguous polygons, then added the canonical lookup specification.

## 2026-09-21 — G2-GEO-012 canonical spec

- Added the canonical Grade 2 polygon-vertices lookup specification using the same unambiguous shape set.

## 2026-09-21 — G2-GEO-013 canonical spec

- Resolved the nonunique-options FLAG by removing rectangle, and extended shared BOOL labels for the unique shape options.

## 2026-09-21 — G2-GEO-014 canonical spec

- Resolved the face-count FLAG by explicitly counting all flat and curved boundary surfaces.

## 2026-09-21 — Taskgen student-read grant

- Added additive migration `000008_grant_taskgen_student_read` granting `taskgen_svc` read access to `students`, allowing taskgen to validate an incoming student foreign key before it writes a generation request.

## 2026-09-22 — CAS evaluation contract

- Added additive migration `000009_add_cas_evaluation_contract`: CAS operation/status and event-type dictionaries; the bounded, leaseable `cas_evaluation_request` queue; completion/failure event types; and a least-privileged `cas_svc` role.
- Exported CAS operation/status, CAS completion/failure event, and queue-row constants/structs from the versioned Go module.

## 2026-09-22 — CAS async API contract draft

- Documented the approved CAS-only asynchronous submission exception in `docs/api-contract.md`.
- The endpoint and worker remain unimplemented pending confirmation of the drafted type specifications.

## 2026-09-22 — Task-type template infrastructure

- Added migration `000010_task_type_templates`, the core template row and fallback lookup contract, and focused lookup tests.
- Seeded the five-type taskgen Phase A pilot with existing wording only; no translation backfill was performed.

## 2026-09-23 — Answer-widget dictionary

- Added the eight-value `answer_widget` dictionary and exported shared `AnswerWidget` constants.
- Activated the shared `latex` render-target constant in `pkg/core`; database seeding is committed in its own migration step.

## 2026-09-23 — Task-type widget columns

- Added non-null `task_type.answer_widget` with a temporary NUMERIC baseline for existing rows, plus nullable JSONB `widget_config`.

## 2026-09-23 — Render-target template key

- Extended `task_type_template` to carry `render_target` and use `(type_id, locale, render_target, spec_version)` as its key; existing rows are preserved as plaintext.

## 2026-09-23 — Activate LaTeX render target

- Seeded `latex` as the third active `render_target` dictionary value; `html-mathml` remains reserved.

## 2026-09-23 — Mechanical answer-widget mapping

- Assigned every existing `task_type` its convention-defined widget from `validation_method`, covering the full catalog without per-type UI guesses.

## 2026-09-23 — BOOL widget choices

- Seeded non-empty `CHOICE.choices` configuration for every BOOL type from the shared validator whitelist, including the quadrant-label branch.

## 2026-09-23 — Answer-widget verification

- Applied migrations `000011`–`000016` to the local catalog and verified all 658 types have non-null widgets; all 106 BOOL types have non-empty choices arrays.
- Added core dictionary tests and the migration verification report.
# 2026-09-23 — Widget metadata and optional LaTeX templates

- Added real `widget_config` metadata for all 105 structured widgets, batched by validation method: 30 `TUPLE_N`, 13 `SET_LIST`, 2 `MATRIX_GRID`, and 60 `STRUCTURED_CANON` types.
- Added one pilot LaTeX companion row for `G5-FRA-003`; arithmetic pilot rows and types without an existing plaintext DB template remain intentionally deferred.
- No generator, validator, plaintext-template, or test behavior changed. See `docs/widget-config-log.md`.

## 2026-09-23 — Phase B Russian template backfill, batch 1

- Added Russian plaintext templates for G3-FRA-009–014 and G3-GEO-001–004. Prompts preserve the same comparison targets and quantities; numeric wordings avoid grammatical number agreement.
- Added additive migration `000025_seed_g3_fraction_geometry_ru_templates` with a scoped down migration. Taskgen rendering changes are committed separately in its repository.

## 2026-09-23 — Phase B Russian template backfill, batch 2

- Added Russian plaintext templates for G3-GEO-005–009 and G3-MEA-009–013. Time values are rendered zero-padded to preserve the displayed clock format; unit prompts avoid assuming a unit absent from the source.
- Added additive migration `000026_seed_g3_geometry_measurement_ru_templates` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 3

- Added Russian plaintext templates for G3-MEA-014–018 and G3-NUM-006, 007, 011, 013, 015. Sequence type and terms are passed as derived template values; division-with-remainder instructions name both answer fields.
- Added additive migration `000027_seed_g3_measurement_number_ru_templates` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 4

- Added Russian plaintext templates for G3-NUM-016–025. Word-problem templates use explicit counts rather than variable noun endings, and arithmetic prompts retain the same operations and unknowns.
- Added additive migration `000028_seed_g3_number_ru_templates` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 5

- Added Russian plaintext templates for G3-NUM-026–036. Sequence terms and derived products are supplied as template values; the word problem uses neutral count labels.
- Added additive migration `000029_seed_g3_number_ru_templates_batch2` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 6

- Added Russian plaintext templates for G3-NUM-037–046: arithmetic and geometric sequences, equality/comparison, rounding, and integer operations.
- Added additive migration `000030_seed_g3_number_ru_templates_batch3` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 7

- Added Russian plaintext templates for G3-NUM-047, G3-STA-001–004, and G6-ALG-001–005. Algebra prompts preserve equation/expansion meaning; chart prompts label each category explicitly.
- Added additive migration `000031_seed_g3_stats_g6_algebra_ru_templates` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 8

- Added Russian plaintext templates for the eight early G3 arithmetic/sequence types missed by a constant-only registry census, plus G6-ALG-006–007. This corrected the initial Grade 3/6 enumeration to 133 total catalog type IDs (77 Grade 3, 56 Grade 6).
- Added additive migration `000032_seed_g3_early_g6_algebra_ru_templates` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-23 — Phase B Russian template backfill, batch 9

- Added Russian plaintext templates for G6-ALG-008–010 and G6-DEC-001–007. Decimal displays and direction labels are formatted as derived template values while numeric generation remains unchanged.
- Added additive migration `000033_seed_g6_algebra_decimal_ru_templates` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-24 — Phase B Russian template backfill, batch 10

- Added Russian plaintext templates for G6-FRA-001–010. Ratio, unit-cost, and fraction prompts preserve the original equations, requested quantities, and comparison targets without variable noun agreement.
- Added additive migration `000034_seed_g6_fraction_ru_templates_batch1` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-24 — Phase B Russian template backfill, batch 11

- Added Russian plaintext templates for G6-FRA-011–015 and G6-GEO-001–005. Fraction ordering inputs are carried as derived text; circle task labels distinguish circumference from area.
- Added additive migration `000035_seed_g6_fraction_geometry_ru_templates_batch2` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-24 — Phase B Russian template backfill, batch 12

- Added Russian plaintext templates for G6-GEO-006–015. Composite dimensions, prism measurements, and net-face descriptions retain their mathematical inputs and targets.
- Added additive migration `000036_seed_g6_geometry_ru_templates_batch3` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-24 — Phase B Russian template backfill, batch 13

- Added Russian plaintext templates for G6-NUM-001, 003–008 and G6-STA-001. Question examples are agreement-invariant or phrased without variable noun agreement; remainder and absolute-value tasks retain their exact targets.
- Added additive migration `000037_seed_g6_number_statistics_ru_templates_batch4` with a scoped down migration. Taskgen changes are committed separately.

## 2026-09-24 — Phase B fresh-database template migration ordering

- Fresh migration replay exposed that the registry catalog is populated by taskgen `Reconcile()`, after schema DDL; template migrations from `000025` onward therefore cannot run before catalog reconciliation because of the `task_type` foreign key.
- Updated `scripts/start-local.sh` to apply migrations through widget-column prerequisites `000012`, run taskgen in reconcile-only mode, then apply template-table/key migrations `000010`, `000013`–`000024`, and the Phase B template seeds. On an existing schema it reconciles first and replays only the idempotent Phase B template seeds.
- This makes the local bootstrap order explicit; taskgen changes are committed separately.

## 2026-09-23 — CAS sign-off status correction

- Updated the canonical SRD's CAS status references to match `taskgen/docs/signoffs/OPEN-06.md` (Ken approval; shared infrastructure gate closed; per-type Confirmation Gates remain).
- Corrected the CAS-related findings in `docs/system-audit-2026-09-23.md` after key-based authentication, successful push verification, and an exact-HEAD scratch-clone comparison.
- Documentation-only change; no schema/module version tag created.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 1

- Added Russian plaintext templates for `G1-NUM-011`–`G1-NUM-020`. The five apple word problems use count-based, agreement-invariant phrasing while preserving each original unknown and operation.
- Added additive migration `000038_seed_g1_number_ru_templates_batch1` with a scoped, reversible down migration. Taskgen rendering changes are committed separately.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 2

- Added Russian plaintext templates for `G1-NUM-021`–`G1-NUM-026` and `G1-MEA-001`–`G1-MEA-004`. The apple word problems use count-based, agreement-invariant phrasing; arithmetic and length prompts preserve their original operands, operation, comparison, and requested quantity.
- Added additive migration `000039_seed_g1_number_measurement_ru_templates_batch2` with a scoped, reversible down migration. Taskgen rendering changes are deliberately uncommitted for separate review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 3

- Added Russian plaintext templates for `G1-MEA-005`–`010` and `G1-STA-001`–`004` in the documented catalog order. The clock prompts retain the `H:MM` answer contract; prompts whose validators still require legacy answer tokens retain those tokens explicitly.
- Added additive migration `000040_seed_g1_measurement_statistics_ru_templates_batch3` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 4

- Added Russian plaintext templates for `G1-GEO-001`–`G1-GEO-009` and `G2-NUM-010` in catalog order. Geometry fractions preserve their numerator/denominator semantics; count phrasing avoids number-dependent agreement. Legacy `2D`/`3D`, `TRUE`/`FALSE`, and shape-code answers are explicitly identified as codes and remain unchanged where validators require them.
- Added additive migration `000041_seed_g1_geometry_g2_number_ru_templates_batch4` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 5

- Added Russian plaintext templates for `G2-NUM-011`–`G2-NUM-020`. Place-value, comparison, ordering, and arithmetic prompts retain their established parameters, operations, and answer contracts.
- Added additive migration `000042_seed_g2_number_ru_templates_batch5` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 6

- Added Russian plaintext templates for `G2-NUM-021`–`G2-NUM-030` in `docs/phase2-loop-log.md` order. Sequence rows use derived rendered terms while preserving their generator parameters and answers; arithmetic, place-value, and comparison rows preserve the existing answer contracts.
- Added additive migration `000043_seed_g2_number_ru_templates_batch6` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 7

- Added Russian plaintext templates for `G2-GEO-011`–`G2-GEO-020` in documented catalog order. Polygon and solid names render in Russian; the source's flat-and-curved-surface convention is stated explicitly; numeric side-count wording avoids Russian numeral agreement; legacy English shape codes and `TRUE`/`FALSE` answer codes remain literal where validation requires them.
- Added additive migration `000044_seed_g2_geometry_ru_templates_batch7` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 8

- Added Russian plaintext templates for `G2-NUM-031`–`040`, starting at the historical loop cursor after `G2-GEO-016`. Arithmetic, missing-number, count, and comparison prompts preserve their exact operation and requested result; the count prompt uses agreement-invariant wording.
- Added additive migration `000045_seed_g2_number_ru_templates_batch8` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 9

- Added Russian plaintext templates for `G2-NUM-041`–`050` in historical implementation-loop order. Boolean and parity answer codes remain the established `TRUE`/`FALSE` and `even`/`odd` (identified as codes in the prompt); the set prompt retains its bracketed, source-order answer contract. Count wording is agreement-invariant.
- Added additive migration `000046_seed_g2_number_ru_templates_batch9` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 10

- Added Russian plaintext templates for `G2-NUM-051`–`G2-NUM-062`, completing the historical `048`–`062` groups. Place-value labels, sequences, comparison operators, and tuple/list answer formats retain their existing mathematical and validator-facing meaning; count wording is agreement-invariant.
- Added additive migration `000047_seed_g2_number_ru_templates_batch10` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 11

- Added Russian plaintext templates for `G2-MEA-009`–`G2-MEA-017` and `G2-STA-001`, following the historical implementation-loop cursor after `G2-NUM-062`. Variable-count wording is agreement-invariant; clock prompts preserve the `H:MM` output format and literal `AM`/`PM` answer codes.
- Added additive migration `000048_seed_g2_measurement_statistics_ru_templates_batch11` with a scoped, reversible down migration. Taskgen rendering changes remain separate and uncommitted for review.

## 2026-09-24 — Phase B Russian template backfill, Stage 2 batch 12

- Added Russian plaintext templates for `G2-STA-002`–`005`, `G2-MEA-018`–`019`, and `G2-GEO-021`–`024` in historical order. Numeric lists are carried through template values; legacy animal/unit/boolean codes remain explicit. Geometry templates preserve row/column products, area, and fixed fraction answers.
- Added additive migration `000049_seed_g2_statistics_geometry_ru_templates_batch12` with a scoped, reversible down migration.
# 2026-09-24 — Phase B batch 13

- Added eleven Russian `plaintext` templates for G2-GEO-025–031 and G4-NUM-001–004, retaining each generator's existing operands, answer encoding, and validation meaning.
- Migration: `000050_seed_g2_geometry_g4_number_ru_templates` with an ID-scoped down migration.
- Verification: fresh bootstrap through migration `000050` retained 658 task types and inserted all 11 rows; batch down deleted 11 and left 0; up replay restored all 11 before the disposable database was dropped. Focused deterministic/oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 14

- Added Russian plaintext templates for G4-NUM-005–006 and G4-FRA-001–008. Prompts preserve the existing numeric expressions and answers; the word prompt uses neutral quantity labels.
- Migration: `000051_seed_g4_number_fraction_ru_templates_batch14`, with exact-ID down migration.
- Verification: fresh bootstrap through `000051` retained 658 task types and inserted all 10 batch rows; down deleted exactly 10 and left 0. Focused generator oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 15

- Added Russian plaintext templates for G4-GEO-001–005, G4-GEO-007, and G4-MEA-002–005. Existing answer codes for geometric classifications are explicitly listed in Russian prompts; unit labels and quantity meaning are preserved. Excluded G4-GEO-006 after detecting that its source claim (a circle has zero symmetry axes) is false; do not translate that premise as if valid.
- Migration: `000052_seed_g4_geometry_measurement_ru_templates_batch15`, with exact-ID down migration.
- Verification: fresh bootstrap through `000052` retained 658 task types, inserted all 10 intended rows, and left G4-GEO-006 without a DB template; down deleted exactly 10 and left 0. Focused generator oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 16

- Added Russian plaintext templates for G4-MEA-006–015 and G4-STA-001, preserving time zero-padding, numeric inputs, and existing answer representations.
- Migration: `000053_seed_g4_measurement_statistics_ru_templates_batch16` with exact-ID down migration.
- Verification: fresh bootstrap through `000053` retained 658 task types, inserted all 11 rows, and down deleted exactly 11 leaving 0. Focused oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 17

- Added Russian plaintext templates for G5-NUM-001–010. Arithmetic expressions, divisibility codes, and expected output encodings remain unchanged.
- Migration: `000054_seed_g5_number_ru_templates_batch17`, with exact-ID down migration.
- Verification: fresh bootstrap through `000054` retained 658 catalog rows and inserted all 10 rows; down deleted exactly 10 and left 0. Focused generator oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 18

- Added Russian templates for G5-FRA-001–002 and G5-FRA-004–010; also replaced the English pilot text for G5-FRA-003 with Russian. The down migration removes only the nine new rows and restores the pilot's prior English text.
- Migration: `000055_seed_g5_fraction_ru_templates_batch18`.
- Verification: fresh bootstrap through `000055` kept 658 catalog rows and all 10 fraction template rows. The down migration removed exactly 9 newly added rows and restored the original G5-FRA-003 pilot text exactly. Focused oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 19

- Added Russian plaintext templates for G5-DEC-001–015, preserving decimal precision, rounding places, comparison tokens, and existing answer encodings.
- Migration: `000056_seed_g5_decimal_ru_templates_batch19`, with exact-ID down migration.
- Verification: fresh bootstrap through `000056` retained 658 catalog rows, inserted 15 rows, and down deleted exactly 15 leaving 0. Focused generator oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 20

- Added Russian plaintext templates for G5-GEO-001–003, G5-MEA-001–007, G5-STA-001, and G5-DIS-001. Existing boolean and choice answer tokens remain unchanged.
- Migration: `000057_seed_g5_geometry_measurement_statistics_discrete_ru_templates_batch20` with exact-ID down migration.
- Verification: fresh bootstrap through `000057` retained 658 catalog rows and inserted 12 rows; down deleted exactly 12 and left 0. Focused generator oracle/golden tests passed in taskgen.

# 2026-09-24 — Phase B batch 21

- Added Russian DB templates for G7-FRA-001–004, G7-DEC-001–004, G7-GEO-001–002, and G7-GEO-004–005. Migration `000058_seed_g7_templates_batch21` has an exact-ID down migration. Generator wiring is committed separately in taskgen.
- Verification: local database retained all 658 task types and contained exactly 12 rows for the batch; rollback/reapply and full migration replay remain part of this batch's verification.

# 2026-09-24 — Phase B batch 22

- Added Russian plaintext template rows for G7-ALG-006–015 in migration `000059_seed_g7_algebra_ru_templates_batch22`, with exact-ID down migration. Generator template-source changes are in taskgen.
- Verification: local DB retained 658 task rows, inserted 10 batch rows, down removed exactly 10, then up restored the rows.

# 2026-09-24 — Phase B batch 23

- Added ten G7-ALG-016–025 Russian templates in migration `000060_seed_g7_algebra_ru_templates_batch23`, plus exact-ID down migration; taskgen generator source changes are separate.
- Verification: local DB retained 658 catalog rows, inserted ten rows, rollback deleted exactly ten, and reapply restored all ten.

# 2026-09-24 — Phase B batch 24

- Added ten G7 mixed-domain Russian templates in migration `000061_seed_g7_templates_batch24`, with exact-ID down migration.
- Verification: local DB retained 658 catalog rows; migration inserted ten, rollback removed exactly ten, and reapply succeeded.

# 2026-09-24 — Phase B batch 25

- Added eleven G7 function Russian plaintext templates in migration `000062_seed_g7_functions_ru_templates_batch25`, with exact-ID rollback.
- Verification: local database retained 658 catalog rows; migration inserted eleven rows, rollback removed all eleven, and reapply succeeded.

# 2026-09-24 — Phase B batch 26

- Added ten G7 geometry Russian templates in migration `000063_seed_g7_geometry_ru_templates_batch26`, with exact-ID down migration.
- Verification: local DB retained 658 catalog rows; migration inserted ten, rollback deleted exactly ten, and reapply succeeded. GEO-021 remains excluded from the batch due its pre-existing integer-truncation issue.

# 2026-09-24 — Phase B batch 27

- Added ten G7 statistics/geometry Russian templates in migration `000064_seed_g7_statistics_geometry_ru_templates_batch27`, with exact-ID down migration. This adds the DB row previously omitted for G7-GEO-010.
- Verification: 658 catalog rows retained, ten rows inserted, down migration deleted exactly ten, then up reapplied cleanly.

# 2026-09-24 — Phase B batch 28

- Added seven G7 algebra/statistics Russian templates in migration `000065_seed_g7_algebra_statistics_ru_templates_batch28`, with exact-ID down migration.
- Verification: local DB retained 658 catalog rows, inserted seven, rolled back exactly seven, and reapplied. Grade 7 now has one deliberately flagged untemplated row, G7-GEO-021.

# 2026-09-24 — Phase B batch 29

- Added ten Grade 8 Russian templates in migration `000066_seed_g8_number_algebra_ru_templates_batch29`, with exact-ID rollback.
- Verification: DB retained 658 catalog rows, inserted ten, rolled back exactly ten, and reapplied. Separately replayed previously unapplied committed seeds `000025`–`000057` to reconcile the local database to repository history.

# 2026-09-24 — Phase B batch 30

- Added ten G8 algebra/functions/geometry Russian templates in migration `000067_seed_g8_algebra_functions_geometry_ru_templates_batch30`, with exact-ID down migration.
- Verification: local DB kept 658 catalog rows, inserted ten, rolled back exactly ten, then reapplied.

# 2026-09-24 — Phase B batch 31

- Added ten Grade 8 algebra Russian plaintext templates in migration `000068_seed_g8_algebra_ru_templates_batch31`, with exact-ID down migration.
- Verification: DB retained 658 catalog rows, inserted ten, down deleted exactly ten, and up reapplied cleanly; 454 distinct Russian plaintext-template type IDs now exist.

# 2026-09-24 — Phase B batch 32

- Added eleven Grade 8 algebra/functions/geometry Russian plaintext templates in migration `000069_seed_g8_algebra_geometry_ru_templates_batch32`, with exact-ID down migration.
- Verification: migration applied cleanly; focused generator seed/oracle tests passed.

# 2026-09-24 — Phase B batch 33

- Added ten Grade 8 geometry/function Russian plaintext templates in migration `000070_seed_g8_geometry_functions_ru_templates_batch33`, with exact-ID down migration.
- Verification: migration applied cleanly; taskgen's grouped fixed-seed/oracle test passed.

# 2026-09-24 — Phase B batch 34

- Added six late-registered Grade 8 Russian templates in migration `000071_seed_g8_late_registry_ru_templates_batch34`, with exact-ID down migration.
- Verification: migration applied cleanly; taskgen focused oracle suites now also assert the six generators return DB-template-backed instances.

# 2026-09-24 — Phase B batch 35

- Added ten Russian plaintext templates for Grade 1–2 number/measurement/shape cases in migration `000072_seed_g1_g2_measurement_ru_templates_batch35`, with exact-ID down migration.
- G2-MEA-006 was deliberately omitted because its existing time prompt and integer-minute answer disagree; it needs a separate mathematical contract decision before localization.
- Verification: migration applied cleanly and focused taskgen seed/oracle/golden tests passed.

# 2026-09-24 — Phase B batch 36

- Added ten Russian plaintext templates for G2 number/coin-value cases in migration `000073_seed_g2_number_ru_templates_batch36`, with exact-ID down migration.
- Verification: migration applied cleanly; taskgen fixed-seed/oracle tests and new DB-template-route assertions passed.

# 2026-09-24 — Phase B batch 37

- Added twelve Grade 4 number Russian plaintext templates in migration `000074_seed_g4_number_ru_templates_batch37`, with exact-ID down migration.
- Verification: migration applied cleanly; taskgen grouped fixed-seed and new template-backed assertions passed.

# 2026-09-24 — Phase B batch 38

- Added ten Grade 4 number Russian plaintext templates in migration `000075_seed_g4_number_ru_templates_batch38`, with exact-ID down migration.
- Verification: migration applied, down removed ten, and reapply restored ten; DB retained all 658 catalog rows and now has 523 unique Russian plaintext-template IDs. Full taskgen suite passed.

# 2026-09-24 — Phase B batch 39

- Added nine Grade 4 number/geometry Russian plaintext templates in migration `000076_seed_g4_number_geometry_ru_templates_batch39`, with exact-ID down migration.
- Verification: migration applied cleanly; focused taskgen seed/oracle tests passed.

# 2026-09-24 — Phase B batch 40

- Added ten Grade 9 algebra, discrete mathematics, functions, and geometry Russian plaintext templates in migration `000077_seed_g9_algebra_discrete_functions_geometry_ru_templates_batch40`, with exact-ID down migration.
- Verification: local down/up cycle removed and restored exactly ten rows; schema tests passed. The DB now has 542 distinct Russian plaintext-template type IDs among 658 catalog rows.

# 2026-09-24 — Phase B batch 41

- Added ten Grade 9 geometry, probability, and statistics Russian plaintext templates in migration `000078_seed_g9_geometry_probability_statistics_ru_templates_batch41`.
- Verification: down/up cycle removed and restored all ten rows; DB has 552 unique RU plaintext-template type IDs out of 658; schema unit tests passed.

# 2026-09-24 — Phase B batch 42

- Added three Grade 9 vector and trigonometry templates in reversible migration `000079_seed_g9_vectors_trigonometry_ru_templates_batch42`.
- Verification: down/up cycle removed and restored all three rows; database has 555 distinct `ru-KZ` plaintext-template types among 658 catalog rows.

# 2026-09-24 — Phase B batch 43

- Added ten Grade 10 algebra, calculus, and functions Russian plaintext rows through migration `000080_seed_g10_algebra_calculus_functions_ru_templates_batch43`.
- Verification: migration down/up removed and restored ten rows; the DB has 565 unique Russian plaintext template type IDs among 658 catalog rows.

# 2026-09-24 — Phase B batch 44

- Added twelve Grade 10 functions, probability, and statistics Russian plaintext templates in reversible migration `000081_seed_g10_functions_probability_statistics_ru_templates_batch44`.
- Verification: down/up removed and restored twelve rows; the DB contains 577 unique `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 45

- Added ten Grade 10/11 Russian plaintext templates in reversible migration `000082_seed_g10_trg_g11_core_ru_templates_batch45`.
- Verification: down/up removed and restored ten rows; the DB contains 587 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 46

- Added six Grade 11 statistics, trigonometry, and vector Russian plaintext templates in reversible migration `000083_seed_g11_statistics_trigonometry_vectors_ru_templates_batch46`.
- Verification: down/up removed and restored six rows; the DB contains 593 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 47

- Added seven University algebra/calculus Russian plaintext templates in reversible migration `000084_seed_university_algebra_calculus_ru_templates_batch47`.
- Verification: down/up removed and restored seven rows; the DB contains 600 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 48

- Added ten University algebra/multivariable-calculus Russian plaintext templates in reversible migration `000085_seed_university_algebra_calculus_more_ru_templates_batch48`.
- Verification: down/up removed and restored ten rows; the DB contains 610 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 49

- Added ten advanced University calculus Russian plaintext templates in reversible migration `000086_seed_university_calculus_advanced_ru_templates_batch49`.
- Verification: down/up removed and restored ten rows; the DB contains 620 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 50

- Added eleven University calculus/discrete-mathematics Russian plaintext templates in reversible migration `000087_seed_university_calculus_discrete_ru_templates_batch50`.
- Verification: down/up removed and restored eleven rows; the DB contains 631 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 51

- Added ten University functions/matrices Russian plaintext templates in reversible migration `000088_seed_university_functions_matrices_ru_templates_batch51`.
- Verification: down/up removed and restored ten rows; the DB contains 641 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows.

# 2026-09-24 — Phase B batch 52

- Added fourteen University number/probability/statistics Russian plaintext templates in reversible migration `000089_seed_university_number_probability_statistics_ru_templates_batch52`.
- Verification: migration applied successfully; the DB contains 655 distinct `ru-KZ` plaintext template type IDs out of 658 catalog rows, with three previously flagged contract-defect types intentionally excluded.

# 2026-09-24 — Phase B Stage 3 LaTeX companions

- Added 182 `ru-KZ` LaTeX companion rows for formula-appropriate grade 5+ domains. Batch 53 uses explicit formula templates; the remaining additive companions preserve the Russian source template inside LaTeX delimiters. Arithmetic-only types remain excluded.
- Verified reversible migrations `000090` and `000091` by down/up; the database reports 182 LaTeX rows.

# 2026-09-24 — Phase B Stage 4 locale cleanup

- Re-audit found five English-language Russian templates plus two language-neutral arithmetic strings. Migration `000092` replaced the five with Russian phrasing; the two neutral strings remain language-independent. No non-neutral English plaintext templates remain.
