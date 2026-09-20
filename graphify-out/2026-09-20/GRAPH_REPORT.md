# Graph Report - schema  (2026-09-20)

## Corpus Check
- 30 files · ~13,919 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 190 nodes · 235 edges · 28 communities (26 shown, 2 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 4 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0dbe404b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- github.com/berdsa/mathprep_schema
- 02 — Requirements
- 00 — Conventions
- AGENTS.md — schema
- 06 — Traceability, Glossary, Stakeholders, Open Items
- 00 — Scope Lock
- 08 — Developer Backlog
- Backend Integration
- 03 — Architecture
- 04 — NFR, Risk, Ops
- 07 — Wave-A Exemplar Task-Type Specs
- Data Governance
- constants.go
- 01 — Current State
- 00 — Индекс артефактов трека `math-task-catalog`
- Agent log
- 05-decisions.md
- 000001_create_phase0_schema.up.sql
- ValidateExactInt

## God Nodes (most connected - your core abstractions)
1. `Agent log` - 13 edges
2. `02 — Requirements` - 10 edges
3. `task_type` - 9 edges
4. `00 — Conventions` - 9 edges
5. `TaskType` - 8 edges
6. `ValidateExactInt()` - 8 edges
7. `AGENTS.md — schema` - 8 edges
8. `06 — Traceability, Glossary, Stakeholders, Open Items` - 8 edges
9. `task_instance` - 7 edges
10. `00 — Scope Lock` - 7 edges

## Surprising Connections (you probably didn't know these)
- `TaskType` --references--> `GradeBand`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `TaskType` --references--> `ValidationMethod`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `TaskType` --references--> `EquivalencePolicy`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `TaskType` --references--> `GenerationMode`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go
- `TaskType` --references--> `TaskTypeStatus`  [EXTRACTED]
  pkg/core/rows.go → pkg/core/constants.go

## Import Cycles
- None detected.

## Communities (28 total, 2 thin omitted)

### Community 1 - "02 — Requirements"
Cohesion: 0.18
Nodes (10): 02 — Requirements, FR-001 — Generate a daily task set with adaptive topic weighting, FR-002 — Validate a submitted answer and return a verdict, FR-003 — Idempotent resubmission, FR-004 — UNPARSEABLE never affects mastery or attempt counters, FR-005 — Defect-triggered invalidation and re-grade, snapshot preserved, FR-006 — Fallback-pool exhaustion never silently shrinks a batch, FR-007 — Generation is mediated by a durable job queue, not an in-request call *(new)* (+2 more)

### Community 2 - "00 — Conventions"
Cohesion: 0.20
Nodes (9): 00 — Conventions, 1. ID scheme, 2. Validation-method legend, normalization, and reason codes, 3. Canonical-form grammar, 4. Difficulty tier model, 5. NotationProfile — `ru-KZ`, 6. Data-dictionary tables — **new this pass, Phase-0 deliverable**, 7. Generation-safety rules (+1 more)

### Community 3 - "AGENTS.md — schema"
Cohesion: 0.22
Nodes (8): AGENTS.md — schema, Conventions, Local infra, Source of truth, Stack, Testing, What this repo is, Workflow

### Community 4 - "06 — Traceability, Glossary, Stakeholders, Open Items"
Cohesion: 0.22
Nodes (8): 06 — Traceability, Glossary, Stakeholders, Open Items, Definition of Done, Glossary — carried forward from `00-scope-lock.md` (single normative copy per quality-gate rule), Migration / rollout / rollback, Traceability matrix, Карта стейкхолдеров, Реестр допущений — consolidated, Реестр открытых вопросов — consolidated

### Community 5 - "00 — Scope Lock"
Cohesion: 0.25
Nodes (7): 00 — Scope Lock, 1. Разрешение `context_binding` (обновлено), 2. В скоупе (обновлено), 3. Вне скоупа (обновлено), 4–7. Глоссарий, карта стейкхолдеров, реестр допущений, реестр открытых вопросов, SCOPE AMENDMENT — SCOPE-AMD-01 (этот ход), Терминологическая правка (самопроверка, не директива оператора)

### Community 6 - "08 — Developer Backlog"
Cohesion: 0.25
Nodes (7): 08 — Developer Backlog, Confirmation Gate (applies before every subsequent type, not just this first one), Cross-cutting notes for the developer, gathered from every chapter's fine print, Deferred phase — Analytics (`analytics` repo, started only after the above is substantially stable), Phase 0 — Schema, tables, dictionaries (`schema` repo), Phase 1 — One task type, end to end (`taskgen` + `grader` repos, first commits), Phase 2+ — Remaining types, one at a time, curriculum order

### Community 7 - "Backend Integration"
Cohesion: 0.25
Nodes (7): 1. Repository split and what each one owns, 2. Shared validation pipeline (lives in `schema`, imported by `grader`), 3. CAS security boundary — reserved, still no consumer, but now schedule-relevant, 4. Golden tests, 5. API contracts, 6. Event journal (FR-008) — write-side contract, Backend Integration

### Community 8 - "03 — Architecture"
Cohesion: 0.29
Nodes (6): 03 — Architecture, Context diagram, ERD — revised (findings A, B, E, G applied), Sequence — answer submission via QR (unchanged pattern, new owning service), Sequence — generation via job queue (FR-007), State machine — TaskInstance lifecycle

### Community 9 - "04 — NFR, Risk, Ops"
Cohesion: 0.29
Nodes (6): 04 — NFR, Risk, Ops, Failure modes, Observability, Performance & availability, RAID register, Security — STRIDE per trust boundary (updated for 3 services)

### Community 10 - "07 — Wave-A Exemplar Task-Type Specs"
Cohesion: 0.29
Nodes (6): 07 — Wave-A Exemplar Task-Type Specs, G3-NUM-001 — Multi-digit addition with carry, G3-NUM-005 — Simple word problem (addition/subtraction) [HYBRID-AI], G3-NUM-014 — Division with remainder, G6-FRA-003 — Fraction addition, unlike denominators, proper result, G6-GEO-009 — Point quadrant identification

### Community 11 - "Data Governance"
Cohesion: 0.29
Nodes (6): Data Governance, Data inventory & classification — updated for USERS/STUDENTS split, Deletion / export, Lawful basis and consent, Minimization & retention, Residency & sub-processors

### Community 12 - "constants.go"
Cohesion: 0.16
Nodes (24): Domain, EquivalencePolicy, EventLog, GenerationMode, GenerationRequest, GenerationRequestStatus, GradeBand, Locale (+16 more)

### Community 13 - "01 — Current State"
Cohesion: 0.33
Nodes (5): 01 — Current State, 1. Что подано, а что нет — без изменений с прошлого хода, 2. Жёсткие технические ограничения — пересмотрены этим ходом, 3. Ранее принятые решения — статус, 4. Что не модифицируется — без изменений

### Community 14 - "00 — Индекс артефактов трека `math-task-catalog`"
Cohesion: 0.50
Nodes (3): 00 — Индекс артефактов трека `math-task-catalog`, Реестр допущений и открытых вопросов — сводный, обновлён, Реестр репозиториев (введён этим ходом, см. ADR-006)

### Community 15 - "Agent log"
Cohesion: 0.14
Nodes (13): 2026-09-19 — Phase 0 base DDL, 2026-09-19 — Phase 0 dictionary seeds, 2026-09-19 — Phase 0 forbidden-write probes, 2026-09-19 — Phase 0 idempotency constraints, 2026-09-19 — Phase 0 migration plan, 2026-09-19 — Phase 0 migration verification, 2026-09-19 — Phase 0 service roles and grants, 2026-09-19 — Phase 0 summary (+5 more)

### Community 17 - "000001_create_phase0_schema.up.sql"
Cohesion: 0.19
Nodes (21): domain, equivalence_policy, event_log, generation_mode, generation_request, grade_band, locale, mastery_topic (+13 more)

### Community 25 - "ValidateExactInt"
Cohesion: 0.31
Nodes (13): ReasonCode, CompareExactInt(), NormalizeExactInt(), ParseExactInt(), TestValidateExactIntBoundary(), TestValidateExactIntCorrect(), TestValidateExactIntIncorrect(), TestValidateExactIntUnparseable() (+5 more)

## Knowledge Gaps
- **90 isolated node(s):** `event_log`, `github.com/berdsa/mathprep_schema`, `What this repo is`, `Source of truth`, `Stack` (+85 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ReasonCode` connect `ValidateExactInt` to `constants.go`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `Submission` connect `constants.go` to `ValidateExactInt`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `event_log`, `github.com/berdsa/mathprep_schema`, `What this repo is` to the rest of the system?**
  _90 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Agent log` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._