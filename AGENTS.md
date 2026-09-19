# AGENTS.md — schema

## What this repo is
Owns every PostgreSQL DDL migration and seed dictionary for the MathPrep project, plus a small versioned Go module of shared dictionary constants, ERD row structs, and the shared answer-validation pipeline (`parse → normalize → compare → verdict`). This is the one disclosed exception to "no shared code between services" — see ADR-007 in `docs/srd/05-decisions.md` for why it exists and what it does *not* cover (no business logic, no HTTP handlers).

## Source of truth
This repo must never contradict `docs/srd/`: `00-index.md`, `00-scope-lock.md`, `01-current-state.md`, `02-requirements.md`, `00-conventions.md`, `03-architecture.md`, `backend-integration.md`, `04-nfr-risk-ops.md`, `data-governance.md`, `05-decisions.md`, `06-traceability.md`, `07-task-type-specs-exemplars.md`, `08-developer-backlog.md`. If a task isn't covered by these, stop and ask — never invent scope. Operating rules (plan/act/log/confirmation boundaries) are in `docs/09-agent-operating-prompts.md`.

## Stack
Go + PostgreSQL only. No Kafka, no Redis (`CON-04`, `CON-09`, ADR-006). Migration tool is the developer's reasonable choice (e.g. `golang-migrate` or `goose`) — not mandated further.

## Local infra
Docker Desktop is already running. **No docker-compose file.** One container, started with its own explicit command:
```
docker run -d \
  --name postgres \
  -e POSTGRES_USER=mathprep \
  -e POSTGRES_PASSWORD=<local dev password — set via shell env, never commit it> \
  -e POSTGRES_DB=mathprep \
  -p 5432:5432 \
  -v mathprep_pgdata:/var/lib/postgresql/data \
  postgres:16
```
Do not add a Kafka container, or any other container, without an explicit go-ahead from Ken — the current architecture (job queue on Postgres) doesn't need one.

## Conventions
- Every dictionary value in `00-conventions.md` §6 is seeded exactly as written.
- Migrations are additive-only until `OPEN-07` (schema reconciliation with the pre-existing `task-bank-generator` catalog) closes.
- Two DB roles: `taskgen_svc`, `grader_svc`, grants exactly as in `08-developer-backlog.md` Phase 0 step 6. `EVENT_LOG` is `INSERT`-only for both.

## Workflow
Plan → act → `docs/agent-log.md` entry → `graphify .` (or `/graphify .` — check its own help the first time, its exact init requirement isn't specified here) → `git commit`, per discrete step. Confirmation is required only at phase boundaries (see `docs/09-agent-operating-prompts.md`), never between stages inside one phase.

## Testing
Migrations must run clean against a fresh local Postgres before committing. Dictionary seed values verified line by line against `00-conventions.md` §6 before Phase 0 is marked done.
