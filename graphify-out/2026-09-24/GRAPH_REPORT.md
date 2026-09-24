# Graph Report - schema  (2026-09-24)

## Corpus Check
- 192 files · ~90,786 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 349 nodes · 351 edges · 185 communities (167 shown, 18 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 27 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7ec28cc2`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- pipeline.go
- constants.go
- 000001_create_phase0_schema.up.sql
- pipeline_test.go
- Locale
- 06 — Traceability, Glossary, Stakeholders, Open Items
- Service: taskgen
- 04 — NFR, Risk, Ops
- Phase 1 — One task type, end to end
- Delivery Integration Contract
- Validation-method legend
- TestAnswerWidgetDictionaryValues
- start-local.sh
- Agent Log
- Scope Amendment 01: Grade 1 to University
- Task: Multi-digit addition (G4-NUM-001)
- 000011_add_answer_widget_dictionary.up.sql
- Answer-widget Migration Report
- Local Service Startup
- 00 — Index of Artifacts
- Scope Amendment 02: Multi-locale Support
- Constraint: Go + PostgreSQL Only
- Constraint: Independent Repositories
- G1-NUM-014 — Add three one-digit numbers
- U-FUN-002 — Sum of a convergent series
- Cross-repository Readiness Audit
- Task-type Template Infrastructure
- Widget Configuration Log
- github.com/berdsa/mathprep_schema

## God Nodes (most connected - your core abstractions)
1. `Result` - 17 edges
2. `Validate()` - 16 edges
3. `ValidateExactInt()` - 12 edges
4. `task_type` - 10 edges
5. `TaskType` - 10 edges
6. `ReasonCode` - 9 edges
7. `Locale` - 8 edges
8. `CASEvaluationRequest` - 8 edges
9. `LookupTaskTypeTemplate()` - 8 edges
10. `06 — Traceability, Glossary, Stakeholders, Open Items` - 8 edges

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

## Communities (185 total, 18 thin omitted)

### Community 0 - "pipeline.go"
Cohesion: 0.16
Nodes (32): ReasonCode, CompareExactInt(), flattenNumericValue(), formatNumericValue(), gcd64(), isQuadrantLabel(), isRoman(), joinInts() (+24 more)

### Community 1 - "constants.go"
Cohesion: 0.14
Nodes (28): AnswerWidget, CASEvaluationOperationType, CASEvaluationRequest, CASEvaluationStatus, Domain, EquivalencePolicy, EventLog, EventType (+20 more)

### Community 2 - "000001_create_phase0_schema.up.sql"
Cohesion: 0.14
Nodes (26): domain, equivalence_policy, event_log, generation_mode, generation_request, grade_band, locale, mastery_topic (+18 more)

### Community 3 - "pipeline_test.go"
Cohesion: 0.19
Nodes (21): T, TestValidateBool(), TestValidateCanonList(), TestValidateCanonStrictForm(), TestValidateClockTime(), TestValidateExactIntAcceptsNegative(), TestValidateExactIntAcceptsSixDigits(), TestValidateExactIntBoundary() (+13 more)

### Community 4 - "Locale"
Cohesion: 0.25
Nodes (11): Locale, TaskTypeTemplate, TaskTypeTemplateStore, templateStoreStub, Context, LookupTaskTypeTemplate(), Context, T (+3 more)

### Community 5 - "06 — Traceability, Glossary, Stakeholders, Open Items"
Cohesion: 0.22
Nodes (8): 06 — Traceability, Glossary, Stakeholders, Open Items, Definition of Done, Glossary — carried forward from `00-scope-lock.md` (single normative copy per quality-gate rule), Migration / rollout / rollback, Traceability matrix, Карта стейкхолдеров, Реестр допущений — consolidated, Реестр открытых вопросов — consolidated

### Community 6 - "Service: taskgen"
Cohesion: 0.32
Nodes (8): FR-007: Durable Job Queue, FR-008: Immutable Event Journal, PostgreSQL: mathprep schema, Service: grader, Shared Module: schema, Service: taskgen, ADR-006: Independent Services via Postgres, ADR-007: Shared Schema Module

### Community 7 - "04 — NFR, Risk, Ops"
Cohesion: 0.29
Nodes (6): 04 — NFR, Risk, Ops, Failure modes, Observability, Performance & availability, RAID register, Security — STRIDE per trust boundary (updated for 3 services)

### Community 8 - "Phase 1 — One task type, end to end"
Cohesion: 0.33
Nodes (7): G1-NUM-013 — Missing minuend, Phase 0 — Schema, tables, dictionaries, Phase 1 — One task type, end to end, grader repository, schema repository, taskgen repository, Minimization & retention

### Community 9 - "Delivery Integration Contract"
Cohesion: 0.50
Nodes (3): HTTP API Contract, Delivery Integration Contract, 00 — Conventions

### Community 10 - "Validation-method legend"
Cohesion: 0.67
Nodes (3): U-CAL-007 — Double integral, U-FUN-001 — Series convergence test, Validation-method legend

## Knowledge Gaps
- **36 isolated node(s):** `github.com/berdsa/mathprep_schema`, `answer_widget`, `Performance & availability`, `Observability`, `Security — STRIDE per trust boundary (updated for 3 services)` (+31 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ReasonCode` connect `pipeline.go` to `constants.go`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `Result` connect `pipeline.go` to `constants.go`, `pipeline_test.go`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `Locale` connect `Locale` to `constants.go`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Validate()` (e.g. with `TestValidateCanonStrictForm()` and `TestValidateMatrix()`) actually correct?**
  _`Validate()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `ValidateExactInt()` (e.g. with `TestValidateExactIntAcceptsNegative()` and `TestValidateExactIntAcceptsSixDigits()`) actually correct?**
  _`ValidateExactInt()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **What connects `github.com/berdsa/mathprep_schema`, `answer_widget`, `Performance & availability` to the rest of the system?**
  _36 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `constants.go` be split into smaller, more focused modules?**
  _Cohesion score 0.14482758620689656 - nodes in this community are weakly interconnected._