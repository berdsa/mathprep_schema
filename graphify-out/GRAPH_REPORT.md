# Graph Report - schema  (2026-09-27)

## Corpus Check
- 246 files · ~106,428 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 513 nodes · 481 edges · 240 communities (217 shown, 23 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 27 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `23c9736a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- pipeline.go
- constants.go
- 000001_create_phase0_schema.up.sql
- 3. Phase 3: Comprehensive User Flow & Micro-UX Specification
- pipeline_test.go
- math-prep-kz-ux-functional-spec.md
- Service: taskgen
- Locale
- Phase 1 — One task type, end to end
- Delivery Integration Contract
- Validation-method legend
- widget_config_data_test.go
- Local platform integration plan
- Agent Log
- Scope Amendment 01: Grade 1 to University
- Task: Multi-digit addition (G4-NUM-001)
- 3.1 Registration, Auth, Identity & Role Linkage Flows
- Answer-widget Migration Report
- 06 — Traceability, Glossary, Stakeholders, Open Items
- 00 — Index of Artifacts
- Scope Amendment 02: Multi-locale Support
- Constraint: Go + PostgreSQL Only
- Constraint: Independent Repositories
- G1-NUM-014 — Add three one-digit numbers
- U-FUN-002 — Sum of a convergent series
- Cross-repository Readiness Audit
- Task-type Template Infrastructure
- Widget Configuration Log
- 04 — NFR, Risk, Ops
- 000098_billing_foundation.up.sql
- Billing schema foundation (migration 000098)
- CAS receipt migration plan
- Grader task type read permission plan
- start-local.sh
- TestAnswerWidgetDictionaryValues
- student-tenant-contract.md
- taskgen-template-read-plan.md
- 000011_add_answer_widget_dictionary.up.sql
- mathprep.access_tenants
- mathprep.access_tenants
- github.com/berdsa/mathprep_schema
- Verified phone identity contract
- mathprep.phone_identity
- platform-api-student-identity-contract.md

## God Nodes (most connected - your core abstractions)
1. `Result` - 17 edges
2. `Validate()` - 16 edges
3. `ValidateExactInt()` - 12 edges
4. `task_type` - 10 edges
5. `TaskType` - 10 edges
6. `3.1 Registration, Auth, Identity & Role Linkage Flows` - 10 edges
7. `ReasonCode` - 9 edges
8. `Locale` - 9 edges
9. `3. Phase 3: Comprehensive User Flow & Micro-UX Specification` - 9 edges
10. `CASEvaluationRequest` - 8 edges

## Surprising Connections (you probably didn't know these)
- `TestValidateCanonStrictForm()` --calls--> `Validate()`  [INFERRED]
  pkg/core/validation/pipeline_test.go → pkg/core/validation/pipeline.go
- `TestValidateMatrix()` --calls--> `Validate()`  [INFERRED]
  pkg/core/validation/pipeline_test.go → pkg/core/validation/pipeline.go
- `TestValidateClockTime()` --calls--> `ValidateClockTime()`  [INFERRED]
  pkg/core/validation/pipeline_test.go → pkg/core/validation/pipeline.go
- `TestValidateInterval()` --calls--> `ValidateInterval()`  [INFERRED]
  pkg/core/validation/pipeline_test.go → pkg/core/validation/pipeline.go
- `TestValidateSet()` --calls--> `ValidateSet()`  [INFERRED]
  pkg/core/validation/pipeline_test.go → pkg/core/validation/pipeline.go

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **System Requirements & Design (SRD)** — docs_srd_00_conventions, docs_srd_00_index, docs_api_contract, docs_integration_delivery_integration [EXTRACTED 1.00]
- **Independent Service Architecture** — docs_srd_03_architecture_taskgen, docs_srd_03_architecture_grader, docs_srd_03_architecture_db [EXTRACTED 1.00]
- **Durable Event Logging Flow** — docs_srd_02_requirements_fr_008, docs_srd_03_architecture_db, docs_srd_03_architecture_taskgen, docs_srd_03_architecture_grader [INFERRED 0.85]
- **Three-Repository Architecture** — docs_srd_backend_integration_schema_repo, docs_srd_backend_integration_taskgen_repo, docs_srd_backend_integration_grader_repo [EXTRACTED 1.00]
- **Task Type Definition and Validation** — docs_srd_07_task_type_specs_exemplars_u_cal_007, docs_srd_math_task_catalog_validation_legend, docs_srd_backend_integration_grader_repo [INFERRED 0.85]

## Communities (240 total, 23 thin omitted)

### Community 0 - "pipeline.go"
Cohesion: 0.16
Nodes (32): ReasonCode, CompareExactInt(), flattenNumericValue(), formatNumericValue(), gcd64(), isQuadrantLabel(), isRoman(), joinInts() (+24 more)

### Community 1 - "constants.go"
Cohesion: 0.14
Nodes (28): AnswerWidget, CASEvaluationOperationType, CASEvaluationRequest, CASEvaluationStatus, Domain, EquivalencePolicy, EventLog, EventType (+20 more)

### Community 2 - "000001_create_phase0_schema.up.sql"
Cohesion: 0.14
Nodes (26): domain, equivalence_policy, event_log, generation_mode, generation_request, grade_band, locale, mastery_topic (+18 more)

### Community 3 - "3. Phase 3: Comprehensive User Flow & Micro-UX Specification"
Cohesion: 0.07
Nodes (28): 3.2 Adaptive Diagnostic & Daily Practice UX, 3.3 Hybrid Paper-to-Digital (QR Scan) Experience, 3.4 Timed Test & Anti-Cheating UX Workflow, 3.5 Age-Adaptive Math Keyboards & Validation UX, 3.6 Role-Based Cabinets & Interactive Analytics Dashboards, 3.7 Subscription, Checkout & Multi-Child Discount UX, 3.8 Role Interaction and Notification Rules, 3. Phase 3: Comprehensive User Flow & Micro-UX Specification (+20 more)

### Community 4 - "pipeline_test.go"
Cohesion: 0.19
Nodes (21): T, TestValidateBool(), TestValidateCanonList(), TestValidateCanonStrictForm(), TestValidateClockTime(), TestValidateExactIntAcceptsNegative(), TestValidateExactIntAcceptsSixDigits(), TestValidateExactIntBoundary() (+13 more)

### Community 5 - "math-prep-kz-ux-functional-spec.md"
Cohesion: 0.10
Nodes (19): 1. Phase 1: Multi-Analyst Debate & Edge-Case Q&A, 2. Phase 2: Agreed UX Principles & State Transition Map, 4.1 Registration and organization placement — all roles, 4.2 Student learning and adaptive practice, 4.3 Paper-to-digital QR workflow, 4.4 Scheduled test, focus event, and submission, 4.5 Parent subscription and bulk license flows, 4. Mermaid User-Flow Diagrams (+11 more)

### Community 6 - "Service: taskgen"
Cohesion: 0.32
Nodes (8): FR-007: Durable Job Queue, FR-008: Immutable Event Journal, PostgreSQL: mathprep schema, Service: grader, Shared Module: schema, Service: taskgen, ADR-006: Independent Services via Postgres, ADR-007: Shared Schema Module

### Community 7 - "Locale"
Cohesion: 0.25
Nodes (11): Locale, TaskTypeTemplate, TaskTypeTemplateStore, templateStoreStub, Context, LookupTaskTypeTemplate(), Context, T (+3 more)

### Community 8 - "Phase 1 — One task type, end to end"
Cohesion: 0.33
Nodes (7): G1-NUM-013 — Missing minuend, Phase 0 — Schema, tables, dictionaries, Phase 1 — One task type, end to end, grader repository, schema repository, taskgen repository, Minimization & retention

### Community 9 - "Delivery Integration Contract"
Cohesion: 0.50
Nodes (3): HTTP API Contract, Delivery Integration Contract, 00 — Conventions

### Community 10 - "Validation-method legend"
Cohesion: 0.67
Nodes (3): U-CAL-007 — Double integral, U-FUN-001 — Series convergence test, Validation-method legend

### Community 11 - "widget_config_data_test.go"
Cohesion: 0.30
Nodes (13): matrixWidgetConfig, taskTypeWidgetRow, tupleWidgetConfig, widgetConfigSnapshot, widgetField, decodeConfig(), equalFields(), equalStrings() (+5 more)

### Community 12 - "Local platform integration plan"
Cohesion: 0.15
Nodes (10): Database and service startup, Local development and deployment, Lovable web checkout, Refreshing the local Docker web container, Changes, Local platform integration plan, Scope, Specification decision (+2 more)

### Community 16 - "3.1 Registration, Auth, Identity & Role Linkage Flows"
Cohesion: 0.15
Nodes (13): 3.1.1 Registration model and responsibility, 3.1.2 Universal account registration entry, 3.1.3 Student registration and school/class assignment, 3.1.4 Parent account and child linking, 3.1.5 Teacher registration and school/class assignment, 3.1.6 School administrator registration and organization assignment, 3.1.7 Regional/ministry official registration and scope assignment, 3.1.8 Authentication methods, verification, and account recovery (+5 more)

### Community 18 - "06 — Traceability, Glossary, Stakeholders, Open Items"
Cohesion: 0.22
Nodes (8): 06 — Traceability, Glossary, Stakeholders, Open Items, Definition of Done, Glossary — carried forward from `00-scope-lock.md` (single normative copy per quality-gate rule), Migration / rollout / rollback, Traceability matrix, Карта стейкхолдеров, Реестр допущений — consolidated, Реестр открытых вопросов — consolidated

### Community 28 - "04 — NFR, Risk, Ops"
Cohesion: 0.29
Nodes (6): 04 — NFR, Risk, Ops, Failure modes, Observability, Performance & availability, RAID register, Security — STRIDE per trust boundary (updated for 3 services)

### Community 29 - "000098_billing_foundation.up.sql"
Cohesion: 0.60
Nodes (5): billing_order, billing_order_child, child_entitlement_period, payment_attempt, verified_provider_event

### Community 30 - "Billing schema foundation (migration 000098)"
Cohesion: 0.40
Nodes (4): Billing schema foundation (migration 000098), Lifecycle and invariants, Records and scope, Service and deployment gates

### Community 31 - "CAS receipt migration plan"
Cohesion: 0.40
Nodes (4): CAS receipt migration plan, Changes, Contract notes, Scope

### Community 32 - "Grader task type read permission plan"
Cohesion: 0.40
Nodes (4): Changes, Evidence basis, Grader task type read permission plan, Scope

### Community 234 - "Verified phone identity contract"
Cohesion: 0.40
Nodes (4): Enrollment and account linking, Rollback, Table and lifecycle, Verified phone identity contract

## Knowledge Gaps
- **104 isolated node(s):** `github.com/berdsa/mathprep_schema`, `answer_widget`, `Local deployment guides`, `Database and service startup`, `Lovable web checkout` (+99 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `3. Phase 3: Comprehensive User Flow & Micro-UX Specification` connect `3. Phase 3: Comprehensive User Flow & Micro-UX Specification` to `3.1 Registration, Auth, Identity & Role Linkage Flows`, `math-prep-kz-ux-functional-spec.md`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `ReasonCode` connect `pipeline.go` to `constants.go`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Why does `Locale` connect `Locale` to `constants.go`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Validate()` (e.g. with `TestValidateCanonStrictForm()` and `TestValidateMatrix()`) actually correct?**
  _`Validate()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `ValidateExactInt()` (e.g. with `TestValidateExactIntAcceptsNegative()` and `TestValidateExactIntAcceptsSixDigits()`) actually correct?**
  _`ValidateExactInt()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **What connects `github.com/berdsa/mathprep_schema`, `answer_widget`, `Local deployment guides` to the rest of the system?**
  _104 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `constants.go` be split into smaller, more focused modules?**
  _Cohesion score 0.14482758620689656 - nodes in this community are weakly interconnected._