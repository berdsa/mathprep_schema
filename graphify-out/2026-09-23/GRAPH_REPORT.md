# Graph Report - schema  (2026-09-23)

## Corpus Check
- 76 files · ~77,668 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 673 nodes · 784 edges · 72 communities (65 shown, 7 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a7fe015b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- 07 — Wave-A Exemplar Task-Type Specs
- Agent log
- constants.go
- pipeline.go
- 000001_create_phase0_schema.up.sql
- Responses
- Widget configuration and LaTeX metadata log
- 02 — Requirements
- 00 — Conventions
- Math Task Type Catalog — Grade 1 to University
- AGENTS.md — schema
- 06 — Traceability, Glossary, Stakeholders, Open Items
- 00 — Scope Lock
- 08 — Developer Backlog
- Backend Integration
- 03 — Architecture
- 04 — NFR, Risk, Ops
- Data Governance
- LookupTaskTypeTemplate
- 01 — Current State
- TestAnswerWidgetDictionaryValues
- 00 — Индекс артефактов трека `math-task-catalog`
- agent-log.md
- 05-decisions.md
- 000011_add_answer_widget_dictionary.up.sql
- answer-widget-migration-report.md
- task-type-template-infrastructure.md
- github.com/berdsa/mathprep_schema

## God Nodes (most connected - your core abstractions)
1. `07 — Wave-A Exemplar Task-Type Specs` - 215 edges
2. `Agent log` - 129 edges
3. `Result` - 17 edges
4. `Validate()` - 16 edges
5. `ValidateExactInt()` - 12 edges
6. `task_type` - 10 edges
7. `TaskType` - 10 edges
8. `02 — Requirements` - 10 edges
9. `ReasonCode` - 9 edges
10. `00 — Conventions` - 9 edges

## Surprising Connections (you probably didn't know these)
- `TaskType` --references--> `GradeBand`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `Validate()` --references--> `ValidationMethod`  [EXTRACTED]
  pkg/core/validation/pipeline.go → pkg/core/constants.go
- `TaskType` --references--> `EquivalencePolicy`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `TaskType` --references--> `GenerationMode`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `TaskType` --references--> `TaskTypeStatus`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go

## Import Cycles
- None detected.

## Communities (72 total, 7 thin omitted)

### Community 0 - "07 — Wave-A Exemplar Task-Type Specs"
Cohesion: 0.01
Nodes (215): 07 — Wave-A Exemplar Task-Type Specs, G10-ALG-001,003..005,007..010 — Rational, theorem, radical, variation, and induction contracts, G10-CAL-001 — Basic limit, G10-PRO-001 — Basic single-event probability, G10-PRO-002 — Compound probability, G10-PRO-003..009 and G10-STA-001 — Sampling, probability, and expected value, G10-TRG-001 — Trigonometric equation, G11-ALG-001 — Linear system via matrices (+207 more)

### Community 1 - "Agent log"
Cohesion: 0.02
Nodes (129): 2026-09-19 — Phase 0 base DDL, 2026-09-19 — Phase 0 dictionary seeds, 2026-09-19 — Phase 0 forbidden-write probes, 2026-09-19 — Phase 0 idempotency constraints, 2026-09-19 — Phase 0 migration plan, 2026-09-19 — Phase 0 migration verification, 2026-09-19 — Phase 0 service roles and grants, 2026-09-19 — Phase 0 summary (+121 more)

### Community 2 - "constants.go"
Cohesion: 0.12
Nodes (32): AnswerWidget, CASEvaluationOperationType, CASEvaluationRequest, CASEvaluationStatus, Domain, EquivalencePolicy, EventLog, EventType (+24 more)

### Community 3 - "pipeline.go"
Cohesion: 0.10
Nodes (53): ReasonCode, CompareExactInt(), flattenNumericValue(), formatNumericValue(), gcd64(), isQuadrantLabel(), isRoman(), joinInts() (+45 more)

### Community 4 - "000001_create_phase0_schema.up.sql"
Cohesion: 0.14
Nodes (26): domain, equivalence_policy, event_log, generation_mode, generation_request, grade_band, locale, mastery_topic (+18 more)

### Community 5 - "Responses"
Cohesion: 0.06
Nodes (32): `200 OK`, request `DONE` with a task set, `200 OK`, request not `DONE`, `200 OK` response, `202 Accepted`, `400 Bad Request`, `400 Bad Request`, `401 Unauthorized`, `401 Unauthorized` (+24 more)

### Community 6 - "Widget configuration and LaTeX metadata log"
Cohesion: 0.50
Nodes (3): Checks, Per-type status, Widget configuration and LaTeX metadata log

### Community 7 - "02 — Requirements"
Cohesion: 0.18
Nodes (10): 02 — Requirements, FR-001 — Generate a daily task set with adaptive topic weighting, FR-002 — Validate a submitted answer and return a verdict, FR-003 — Idempotent resubmission, FR-004 — UNPARSEABLE never affects mastery or attempt counters, FR-005 — Defect-triggered invalidation and re-grade, snapshot preserved, FR-006 — Fallback-pool exhaustion never silently shrinks a batch, FR-007 — Generation is mediated by a durable job queue, not an in-request call *(new)* (+2 more)

### Community 8 - "00 — Conventions"
Cohesion: 0.20
Nodes (9): 00 — Conventions, 1. ID scheme, 2. Validation-method legend, normalization, and reason codes, 3. Canonical-form grammar, 4. Difficulty tier model, 5. NotationProfile — `ru-KZ`, 6. Data-dictionary tables — **new this pass, Phase-0 deliverable**, 7. Generation-safety rules (+1 more)

### Community 9 - "Math Task Type Catalog — Grade 1 to University"
Cohesion: 0.20
Nodes (9): Grade 10–11 (ages 15–18), Grade 1–2 (ages 6–8), Grade 3–4 (ages 8–10), Grade 5–6 (ages 10–12), Grade 7–9 (ages 12–15), Math Task Type Catalog — Grade 1 to University, Notes for implementation (methodologist + BA perspective), University (higher mathematics) (+1 more)

### Community 10 - "AGENTS.md — schema"
Cohesion: 0.22
Nodes (8): AGENTS.md — schema, Conventions, Local infra, Source of truth, Stack, Testing, What this repo is, Workflow

### Community 11 - "06 — Traceability, Glossary, Stakeholders, Open Items"
Cohesion: 0.22
Nodes (8): 06 — Traceability, Glossary, Stakeholders, Open Items, Definition of Done, Glossary — carried forward from `00-scope-lock.md` (single normative copy per quality-gate rule), Migration / rollout / rollback, Traceability matrix, Карта стейкхолдеров, Реестр допущений — consolidated, Реестр открытых вопросов — consolidated

### Community 12 - "00 — Scope Lock"
Cohesion: 0.25
Nodes (7): 00 — Scope Lock, 2. В скоупе (обновлено), 3. Вне скоупа (обновлено), 4–7. Глоссарий, карта стейкхолдеров, реестр допущений, реестр открытых вопросов, SCOPE AMENDMENT — SCOPE-AMD-01 (этот ход), SCOPE AMENDMENT — SCOPE-AMD-02 (this pass), SCOPE AMENDMENT — SCOPE-AMD-03 (this pass)

### Community 13 - "08 — Developer Backlog"
Cohesion: 0.25
Nodes (7): 08 — Developer Backlog, Confirmation Gate (applies before every subsequent type, not just this first one), Cross-cutting notes for the developer, gathered from every chapter's fine print, Deferred phase — Analytics (`analytics` repo, started only after the above is substantially stable), Phase 0 — Schema, tables, dictionaries (`schema` repo), Phase 1 — One task type, end to end (`taskgen` + `grader` repos, first commits), Phase 2+ — Remaining types, one at a time, curriculum order

### Community 14 - "Backend Integration"
Cohesion: 0.25
Nodes (7): 1. Repository split and what each one owns, 2. Shared validation pipeline (lives in `schema`, imported by `grader`), 3. CAS security boundary — reserved, still no consumer, but now schedule-relevant, 4. Golden tests, 5. API contracts, 6. Event journal (FR-008) — write-side contract, Backend Integration

### Community 15 - "03 — Architecture"
Cohesion: 0.29
Nodes (6): 03 — Architecture, Context diagram, ERD — revised (findings A, B, E, G applied), Sequence — answer submission via QR (unchanged pattern, new owning service), Sequence — generation via job queue (FR-007), State machine — TaskInstance lifecycle

### Community 16 - "04 — NFR, Risk, Ops"
Cohesion: 0.29
Nodes (6): 04 — NFR, Risk, Ops, Failure modes, Observability, Performance & availability, RAID register, Security — STRIDE per trust boundary (updated for 3 services)

### Community 17 - "Data Governance"
Cohesion: 0.29
Nodes (6): Data Governance, Data inventory & classification — updated for USERS/STUDENTS split, Deletion / export, Lawful basis and consent, Minimization & retention, Residency & sub-processors

### Community 18 - "LookupTaskTypeTemplate"
Cohesion: 0.36
Nodes (7): TaskTypeTemplateStore, Context, LookupTaskTypeTemplate(), T, TestLookupTaskTypeTemplateFallsBackToPrimaryLocale(), TestLookupTaskTypeTemplateReportsMissingTemplate(), TestLookupTaskTypeTemplateUsesRequestedLocale()

### Community 19 - "01 — Current State"
Cohesion: 0.33
Nodes (5): 01 — Current State, 1. Что подано, а что нет — без изменений с прошлого хода, 2. Жёсткие технические ограничения — пересмотрены этим ходом, 3. Ранее принятые решения — статус, 4. Что не модифицируется — без изменений

### Community 21 - "00 — Индекс артефактов трека `math-task-catalog`"
Cohesion: 0.50
Nodes (3): 00 — Индекс артефактов трека `math-task-catalog`, Реестр допущений и открытых вопросов — сводный, обновлён, Реестр репозиториев (введён этим ходом, см. ADR-006)

## Knowledge Gaps
- **451 isolated node(s):** `github.com/berdsa/mathprep_schema`, `answer_widget`, `What this repo is`, `Source of truth`, `Stack` (+446 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Agent log` connect `Agent log` to `agent-log.md`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Why does `ReasonCode` connect `pipeline.go` to `constants.go`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Validate()` (e.g. with `TestValidateCanonStrictForm()` and `TestValidateMatrix()`) actually correct?**
  _`Validate()` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `github.com/berdsa/mathprep_schema`, `answer_widget`, `What this repo is` to the rest of the system?**
  _451 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `07 — Wave-A Exemplar Task-Type Specs` be split into smaller, more focused modules?**
  _Cohesion score 0.009259259259259259 - nodes in this community are weakly interconnected._
- **Should `Agent log` be split into smaller, more focused modules?**
  _Cohesion score 0.015503875968992248 - nodes in this community are weakly interconnected._
- **Should `constants.go` be split into smaller, more focused modules?**
  _Cohesion score 0.12380952380952381 - nodes in this community are weakly interconnected._