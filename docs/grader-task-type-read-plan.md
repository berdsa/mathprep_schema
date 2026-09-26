# Grader task type read permission plan

## Scope

Allow the existing grader task type cache to read task type metadata at startup. The grader already receives `SELECT` on `task_instance`, but its Phase 0 privileges do not include the `task_type` relation used by both its cache and submission lookup queries.

## Changes

1. Add additive migration `000096_grant_grader_task_type_read` granting only `SELECT` on `task_type` to `grader_svc`, with a matching down migration.
2. Verify the grader privilege matrix against a fresh synthetic Postgres database built from the relevant schema and grants: task type/instance reads, submission/mastery writes, event log insert-only, and no task instance writes or event log updates.
3. Record the result, update graphify, and commit only this step's files.

## Evidence basis

`grader/internal/server/task_type_cache.go` loads and looks up rows from `task_type`; `grader/internal/server/server.go` and `cas.go` join the same table to grade submissions. `000004_create_service_roles.up.sql` grants `grader_svc` `SELECT` on `task_instance` but does not grant `SELECT` on `task_type`. No grader SQL reads locale, verdict, or reason-code dictionaries directly.
