# Cross-repository readiness audit — 2026-09-23

Scope: `schema`, `taskgen`, `grader`, and `cas`. Commands were run in each repo unless noted. The database evidence below is from the live local PostgreSQL container (`postgres`, DB `mathprep`).

## BA — catalog and metadata

**[MEDIUM] Catalog/registry reconciliation.** The current catalog markdown has 91 implemented rows and 667 not-yet-implemented source rows: 758 source rows total. The live generator registry test asserts 658 definitions (`taskgen/internal/generator/registry_test.go:38`), and the DB has 658 `task_type` rows. Live DB status counts: `FINAL=0`, `GATED=658`. `taskgen/docs/BLOCKED.md` contains six `CURRENT STATUS: BLOCKED` lines but only five unique IDs: `UNI-CAL-005` is duplicated, so the unique currently blocked count is five (all university types). Thus 91+667 still reconciles in the source catalog, but source rows are not the same unit as registered concrete types. Evidence: `math-task-catalog_updated.md` §§“Implemented types” and “Not yet implemented”; SQL `SELECT status,count(*) FROM task_type GROUP BY status` returned `GATED|658`; `rg -c '^\\- CURRENT STATUS: BLOCKED' taskgen/docs/BLOCKED.md` returned 6 and the ID list has one duplicate.

**[HIGH] Russian locale templates are still absent and the count drifted.** There are six `ru-KZ` rows in `task_type_template`, up from the previous five-row baseline, but **0/6 contains genuine Russian text**: `G3-FRA-008` is English; the other five templates (including both render targets for `G5-FRA-003`) are formula-only. The all-type rendered audit remains 658/658 mismatches (573 English/Latin, 85 language-neutral/math; zero matches). Evidence: live SQL selecting all `ru-KZ` templates; `taskgen/docs/locale-rendering-audit-2026-09-22.md`.

**[PASS] Widget data completeness in the DB.** All 658 rows have a non-null `answer_widget`. Of the kinds that require `widget_config`, 211/211 are populated (CHOICE 106, MATRIX_GRID 2, SET_LIST 13, STRUCTURED_CANON 60, TUPLE_N 30); all 106 CHOICE rows have a non-empty `choices` array. SQL checks returned `658|658`, then `0` required-config nulls and `0` empty/missing CHOICE arrays.

## SA — architecture and contracts

**[PASS] ADR-002 / ADR-003 / ADR-006.** Production grading delegates validation to the shared `schema/pkg/core/validation` pipeline (`grader/internal/validation`); no second production parser/normalizer/validator implementation was found by searches for validator entry points, parsing, regex compilation, and answer comparison in `taskgen/internal` and `grader/internal`. Grader reads the stored issued answer (`correct_answer_json`) rather than regenerating from an instance seed. Imports and service references show the services depend on the versioned schema module; no taskgen↔grader↔CAS internal imports or direct service HTTP calls were found. Evidence: `schema/docs/srd/05-decisions.md` ADRs 002/003/006; `schema/pkg/core/validation/pipeline.go`; `grader/internal/validation`; `grader/internal/repository`; `taskgen/go.mod`, `grader/go.mod`, `cas/go.mod`; searches `rg -n 'math_gen/(taskgen|grader|cas)|http://(taskgen|grader|cas)' ...`.

**[PASS] ADR-007 package scope.** `schema/pkg/core` contains dictionary constants, row structs, template lookup/types, and the validation pipeline only; it has no HTTP handlers or service/business workflows. Evidence: `schema/pkg/core/*.go`, `schema/pkg/core/validation/*.go` and ADR-007 in `schema/docs/srd/05-decisions.md`.

**[RESOLVED in follow-up] CAS sign-off prose was stale.** The live DB has `cas_evaluation_request`; `cas_svc` is `NOLOGIN`, can SELECT/INSERT and update the limited queue columns, cannot DELETE, and can INSERT `event_log`. The migration matches the intended narrow queue role. The canonical SRD status has now been aligned to `taskgen/docs/signoffs/OPEN-06.md`, which records Ken's approval and closure. DB privilege query: `cas_table=cas_evaluation_request`, `cas_svc_login=f`, `can_select=t`, `can_insert=t`, `can_delete=f`, `event_insert=t`.

**[RESOLVED in follow-up] CAS remote backup.** Initial `git ls-remote origin HEAD` failed with `Permission denied (publickey)`. After loading the specified SSH identity, fetch showed the remote already matched local; `git push origin HEAD:main` returned `Everything up-to-date`. An independent scratch clone fetched `HEAD` and verified exact equality: both were `d9c04c28a196e71951c201e12411b4dc0e1dc3a5`. Remote: `git@gitlab.com:math_gen/cas.git`.

## Dev — builds, local run, and historical issues

**[PASS] Fresh builds.** `GOTOOLCHAIN=auto go build ./...` exited 0 in each of the four repos. The default local Go 1.24.3 is older than the repos’ declared Go 1.27.1, so the tested command enabled automatic toolchain selection.

**[PASS, with bounded limitation] Local startup script.** Added `schema/scripts/start-local.sh` and `schema/docs/local-development.md`; actually ran the script against the local PostgreSQL 16 container and DB. It brought up taskgen on `:8081` and grader on `:8082`; taskgen logged “connected to database” and “taskgen listening.” Live probes returned taskgen `GET / → 404`, grader `GET / → 405` (expected unsupported methods/routes). Ctrl-C stops the services; PostgreSQL is left running. Existing databases are deliberately not migrated automatically; the README says to apply reviewed migrations explicitly. No docker-compose is used. During this test the current DB was already migrated (`public.task_type` exists).

**[PASS] Reconciliation compatibility fix.** That real start uncovered taskgen’s upsert omitted the schema’s now-required `answer_widget`; PostgreSQL rejected it before conflict resolution. `taskgen/internal/generator/registry.go` now derives the mechanical widget default from `validation_method` in the INSERT while preserving any existing `widget_config` on conflict. The full taskgen suite and build passed after this change.

**[MEDIUM] Startup prerequisites / migration caveat.** On an empty DB, the script applies sorted `migrations/*.up.sql`. On a DB with `task_type` present, it intentionally skips replay; it does not track individual migration versions. Operators must review/apply later migrations explicitly. This is documented to avoid unsafe replay of non-idempotent DDL.

**[LOW] “Legacy zero-node” fixture warning explained.** Graphify’s six historical JSON paths are fixture data, not unparsed Go source: `G3-NUM-002.json`, `G3-NUM-003.json`, `G4-NUM-001.json`, `G4-NUM-005.json`, `G5-FRA-003.json`, and `G6-FRA-004.json`. They are JSON arrays consumed by generator golden tests. Treating them as zero-node code inputs is safe; the current graph run likewise notes fixture JSON collections (taskgen 79 JSON files, grader 658 JSON files), not missing source dependencies. Evidence: `taskgen/testdata/golden/*.json`, `grader/testdata/golden/*.json`, and the test readers under each repo’s test packages.

**[MEDIUM] Failed-request cleanup note not reproducible from the referenced report.** Searches of the E2E reports and docs did not find the phrase or a cleanup defect description, so the precise historical allegation cannot be identified. The live failure path found in `taskgen/internal/repository/generation.go` appends `GENERATION_FAILED` and marks the request `FAILED` transactionally; service code defers rollback for incomplete transactions. I found no separate delete/cleanup worker or dangling-record cleanup path. Conclusion: no demonstrated cleanup defect to fix from available evidence; the old note should be treated as unverified, not as a confirmed resolved issue.

## QA — fresh tests and coverage

**[PASS] Fresh `go test -count=1 ./...` outputs:**

```text
schema:
ok   github.com/berdsa/mathprep_schema/pkg/core            0.464s
ok   github.com/berdsa/mathprep_schema/pkg/core/validation 0.815s

taskgen:
?    gitlab.com/math_gen/taskgen/cmd/taskgen              [no test files]
ok   gitlab.com/math_gen/taskgen/internal/api             0.516s
?    gitlab.com/math_gen/taskgen/internal/config          [no test files]
ok   gitlab.com/math_gen/taskgen/internal/generator       14.520s
?    gitlab.com/math_gen/taskgen/internal/handler         [no test files]
?    gitlab.com/math_gen/taskgen/internal/logger          [no test files]
?    gitlab.com/math_gen/taskgen/internal/middleware      [no test files]
?    gitlab.com/math_gen/taskgen/internal/model           [no test files]
ok   gitlab.com/math_gen/taskgen/internal/observability   1.257s
ok   gitlab.com/math_gen/taskgen/internal/repository      1.627s
ok   gitlab.com/math_gen/taskgen/internal/service         1.939s

grader:
?    github.com/math_gen/grader/cmd/grader                [no test files]
ok   github.com/math_gen/grader/internal/server           1.372s
ok   github.com/math_gen/grader/internal/validation       1.783s

cas:
?    github.com/berdsa/mathprep_cas/cmd/cas-worker        [no test files]
ok   github.com/berdsa/mathprep_cas/internal/core          1.156s
```

**[HIGH] Golden fixture counts are not all aligned.** Grader has exactly 658 `testdata/golden/*.json` files, matching the 658 registry types. Taskgen has 79 per-type JSON golden files—not 658—even though its registry asserts 658 types and many other type tests exercise deterministic seed ranges through shared helpers. So the literal golden/oracle fixture-count check requested does **not** match in taskgen. Evidence: `find grader/testdata/golden -name '*.json' | wc -l` → 658; `find taskgen/testdata/golden -name '*.json' | wc -l` → 79; `taskgen/internal/generator/registry_test.go:38`.

**[MEDIUM] Widget-config test coverage is not data validation.** `schema/pkg/core/widgets_test.go` tests the eight widget dictionary constants, not JSON config shape/content or task_type rows; `rg` found no test asserting `choices`, tuple labels/count, set/matrix config, or canonical templates. DB values currently pass completeness queries, but there is no regression test protecting those populated configs.

## DevOps — graphify and cleanliness

**Graphify code graphs were run in all four repos** via `graphify update .`, with generated current snapshots in each `graphify-out/2026-09-23/`. Extraction summary: schema 685 nodes / 795 edges / 72 communities; taskgen 7,529 / 14,804 / 963; grader 275 / 275 / 28; CAS 278 / 351 / 28. Fixture JSON warnings were classified above as expected test data, not code. Generated outputs are committed per repo.

**Semantic extraction status: semantic/document extraction remains unavailable; set and authorize a supported model API key in the environment (for example `GEMINI_API_KEY` or `GOOGLE_API_KEY`) and rerun `graphify .` to enable it.** Code graph extraction did run; no semantic extraction was silently substituted.

## Git state / commits

Pre-cleanup dirty paths consisted of the updated vendored `docs/srd/00-conventions.md` in all four repos; `schema/go.mod`; CAS’s updated vendored SRD files (`00-scope-lock.md`, `07-task-type-specs-exemplars.md`, `08-developer-backlog.md`, `backend-integration.md`, `data-governance.md`); taskgen’s `internal/generator/registry.go` and locale audit; graphify’s root report/graph/manifest/labels/stat-index/HTML plus `graphify-out/2026-09-23/` output in each repo; OS `.DS_Store` files; and Graphify AST cache JSON files. The cache and `.DS_Store` paths are now covered by each repo’s `.gitignore`; generated graph outputs and scoped source/docs changes are committed separately within their own repositories. Final verification: `git status --short` is empty in all four repos.
