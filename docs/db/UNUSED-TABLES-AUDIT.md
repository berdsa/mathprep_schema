# Live-table usage audit

Audit time: 2026-10-01 (Asia/Almaty). Database: `mathprep`, PostgreSQL 16.15.
This is a read-only, current-project-scope audit; it does **not** authorize or
perform removal of any relation.

## Scope and method

The audit covered the current Go sources and current container topology for
`taskgen`, `grader`, `cas`, `platform-api`, `notifications`, `payments`,
`generator`, and `auxiliary/auth`, excluding vendored code and archived source
from runtime evidence. The running containers were `postgres`, taskgen,
grader, platform-api, notifications, payments, auth, web, and Redis; no CAS
container was running. [DB] `docker ps` 2026-10-01; [CODE]
`taskgen/cmd/taskgen/main.go:21-29`, `grader/cmd/grader/main.go`,
`cas/cmd/cas-worker/main.go`, `platform-api/cmd/platform-api/main.go:45-58`,
`notifications/cmd/notifications/main.go:31-35`.

Every catalog query used `PGOPTIONS='-c default_transaction_read_only=on'`.
Inventory was taken twice from `pg_class`/`pg_namespace`; both checks returned
128 ordinary/partitioned tables (33 `public`, 95 `mathprep`), no partitions,
no RLS policies, and no user views. Exact `count(*)` was safe at this small
local snapshot; table sizes and structural counts came from `pg_total_relation_size`,
`pg_constraint`, `pg_index`, and `pg_trigger`. [DB] catalog queries recorded
in `DB-DOCUMENTATION.md` §Verification queries.

Static evidence used `rg -n --glob '*.go' --glob '!**/*_test.go'
--glob '!**/archive/**'` for every live relation name plus focused searches of
`Query`, `Exec`, `QueryRow`, DSN construction, `search_path`, and `SET ROLE`.
Graphify reports were inspected only as secondary evidence; their snapshots
predate current heads for several repositories. [GRAPH]
`schema/graphify-out/GRAPH_REPORT.md`, `taskgen/graphify-out/GRAPH_REPORT.md`,
`grader/graphify-out/GRAPH_REPORT.md`, `cas/graphify-out/GRAPH_REPORT.md`.

Limits: PostgreSQL catalogs do not retain table creation timestamps. Scan
counters are resettable and only corroborate use; they do not prove it. Empty
tables, FKs, migration text, and static negative searches do not prove a table
is obsolete. The active Auth container is configured in platform-session mode,
so its legacy direct database path is not reached
(`auxiliary/auth/cmd/server/main.go:45-72`,
`deploy/local/docker-compose.yml:112-130`). Potential external administrative
or operational consumers are still not ruled out. Therefore no table is called
"confirmed unused".

Legend: `A` = `ACTIVE_RUNTIME`; `I` = `REQUIRED_INDIRECT`; `R` =
`REQUIRED_INFRASTRUCTURE`; `E` = `IMPLEMENTED_NOT_ENABLED`; `P` =
`PLANNED_ONLY`; `U` = `UNUSED_CANDIDATE`; `?` = `UNKNOWN`.
`TG`, `GR`, `CAS`, `PA`, and `NT` identify taskgen, grader, CAS, platform API,
and notifications. `public` runtime SQL was historically unqualified in TG/GR/CAS;
PA/NT SQL is already mostly qualified. Counts are the exact audit snapshot;
all table sizes are under 1 MiB. [CODE] `taskgen/internal/repository/generation.go:49-284`,
`grader/internal/server/server.go:109-214`, `cas/internal/core/worker.go`,
`platform-api/internal/platformidentity/http.go:600-940`,
`notifications/internal/outbox/worker.go:97-165`.

## Complete live inventory and current-use classification

Columns: relation; status; known current consumer/RW contract; exact rows;
structural notes. "catalog" means a live dictionary required by a FK, check,
or active query even where code does not name it directly.

### Engine schema (`public`)

| Relation | Status | Consumer / operations | Rows | Structural dependency and confidence |
|---|---|---|---:|---|
| `public.answer_widget` | I | TG/PA catalog reads | 8 | referenced by active task catalogue; high |
| `public.billing_order` | A | PA read/insert/update | 1 | billing parent; high |
| `public.billing_order_child` | A | PA read/insert | 2 | FK to order; high |
| `public.cas_evaluation_request` | E | GR enqueue; CAS worker claims/writes | 0 | CAS code reachable when enabled, no running container; high |
| `public.cas_evaluation_status` | I | CAS queue dictionary | 4 | required by CAS request constraint; high |
| `public.cas_operation_type` | I | CAS operation dictionary | 1 | required by CAS request constraint; high |
| `public.cas_submission` | E | GR/PA receipt reads/writes; CAS completion | 0 | CAS implementation not deployed; high |
| `public.child_entitlement_period` | A | PA billing lifecycle R/W | 0 | FK to billing child; high |
| `public.domain` | I | TG/GR active task catalogue | 15 | dictionary FK/check contract; high |
| `public.equivalence_policy` | I | GR task cache/validation | 3 | task-type contract; high |
| `public.event_log` | A | TG/GR/CAS insert-only journal | 279 | append-only ACL (`a` only to service groups); high |
| `public.event_type` | I | active journal event dictionary | 7 | FK/check contract; high |
| `public.generation_mode` | I | TG/GR task-type cache | 2 | task-type contract; high |
| `public.generation_request` | A | TG claim/lease/insert/update | 81 | queue; high |
| `public.grade_band` | I | active task catalogue | 12 | task-type contract; high |
| `public.locale` | I | TG/GR/PA active locale contract | 3 | task/template/request constraints; high |
| `public.mastery_topic` | A | GR upsert; TG/PA reads | 14 | guarded by trigger; high |
| `public.payment_attempt` | A | PA billing lifecycle R/W | 1 | FK to billing order; high |
| `public.reason_code` | I | GR/CAS verdict contract | 10 | submission/CAS constraints; high |
| `public.render_target` | I | TG/PA rendering contract | 3 | task instance/type constraints; high |
| `public.students` | A | TG read; PA bridge creates/updates | 205 | FK from engine assignments; high |
| `public.submission` | A | GR insert/read; PA reads | 142 | FK to task/student; high |
| `public.task_instance` | A | TG insert/read; GR read | 239 | frozen-answer contract; high |
| `public.task_set` | A | TG insert/read; GR read | 75 | FK to request/student; high |
| `public.task_type` | A | TG registry/cache; GR/PA reads | 658 | active catalogue; high |
| `public.task_type_status` | I | TG eligible-status lookup | 3 | task-type constraint; high |
| `public.task_type_template` | A | TG template reads | 840 | FK to active task type; high |
| `public.tier_code` | I | task-type/task-instance contract | 3 | FK/check contract; high |
| `public.user_type` | I | PA bridge identity contract | 3 | `users` constraint; high |
| `public.users` | A | PA bridge creates/updates | 205 | parent of students; high |
| `public.validation_method` | I | TG/GR validation cache | 9 | task-type contract; high |
| `public.verdict` | I | GR/CAS/PA result contract | 3 | submission/CAS constraints; high |
| `public.verified_provider_event` | A | PA payment idempotency R/W | 0 | FK/unique correlation contract; high |

### Platform schema (`mathprep`)

| Relation | Status | Consumer / operations | Rows | Structural dependency and confidence |
|---|---|---|---:|---|
| `mathprep.access_audit_events` | A | PA inserts safe audit events | 1294 | append-only operational journal; high |
| `mathprep.access_consents` | A | PA consent R/W | 469 | guarded FKs/triggers; high |
| `mathprep.access_external_identities` | U | no current direct Go reference | 1 | Auth ruled out; external admin consumer unresolved; low |
| `mathprep.access_guardian_relationships` | A | PA identity/school R/W | 405 | tenant guard trigger; high |
| `mathprep.access_invitations` | ? | no current direct Go reference | 0 | external/admin consumer not ruled out; low |
| `mathprep.access_legacy_parent_mappings` | A | PA preauth/Google bridge reads | 474 | legacy bridge still active; high |
| `mathprep.access_memberships` | A | PA/NT authorization reads and writes | 1092 | active principal/tenant bridge; high |
| `mathprep.access_principals` | A | PA/NT identity R/W | 1162 | root identity relation; high |
| `mathprep.access_recovery_cases` | ? | no current direct Go reference | 0 | external/admin consumer not ruled out; low |
| `mathprep.access_tenants` | A | PA authorization R/W | 715 | active tenant root; high |
| `mathprep.adaptation_rule_versions` | P | no enabled implementation | 1 | content/adaptation contract only; medium |
| `mathprep.answer_evaluation_revisions` | P | no enabled implementation | 0 | assessment subsystem contract; medium |
| `mathprep.assistance_marks` | P | no enabled implementation | 0 | assessment subsystem contract; medium |
| `mathprep.attempt_answers` | P | no enabled implementation | 0 | assessment subsystem contract; medium |
| `mathprep.attempt_score_revisions` | P | no enabled implementation | 0 | assessment subsystem contract; medium |
| `mathprep.attempts` | P | no enabled implementation | 0 | assessment subsystem contract; medium |
| `mathprep.backup_artifact_manifests` | P | no current backup runner | 0 | operations-design contract only; medium |
| `mathprep.backup_runs` | P | no current backup runner | 0 | operations-design contract only; medium |
| `mathprep.content_decision_events` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.content_incident_pack_items` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.content_incidents` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.content_readiness_run_days` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.content_readiness_runs` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.content_reports` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.curriculum_versions` | P | no enabled content service | 2 | content catalogue root; medium |
| `mathprep.deletion_requests` | P | no current deletion runner | 0 | governance workflow only; medium |
| `mathprep.difficulty_override_events` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.difficulty_overrides` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.item_instances` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.item_version_skills` | P | no enabled content service | 96 | content subsystem; medium |
| `mathprep.item_versions` | P | no enabled content service | 96 | content subsystem; medium |
| `mathprep.items` | P | no enabled content service | 96 | content subsystem; medium |
| `mathprep.job_attempts` | P | no active platform job runner | 0 | jobs subsystem; medium |
| `mathprep.jobs` | P | no active platform job runner | 0 | jobs subsystem; medium |
| `mathprep.learner_profiles` | U | no current direct Go reference | 4 | profile cluster only; external consumer unresolved; low |
| `mathprep.learner_skill_projection` | P | analytics deferred | 0 | analytics/read model; high |
| `mathprep.learners` | A | PA identity/school R/W | 407 | FK/trigger dependencies; high |
| `mathprep.operation_events` | P | no current ops writer | 0 | operations subsystem; medium |
| `mathprep.pack_access_tokens` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.pack_artifacts` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.pack_item_skills` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.pack_item_voids` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.pack_items` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.pack_lifecycle_events` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.packs` | P | no enabled pack service | 0 | pack subsystem; medium |
| `mathprep.parent_active_profiles` | U | no current direct Go reference | 1 | parent/profile cluster; external consumer unresolved; low |
| `mathprep.parent_command_receipts` | U | no current direct Go reference | 0 | parent/profile cluster; external consumer unresolved; low |
| `mathprep.parent_consents` | U | no current direct Go reference | 2 | parent/profile cluster; external consumer unresolved; low |
| `mathprep.parents` | A | PA identity/Google R/W | 474 | active legacy bridge; high |
| `mathprep.phone_identity` | A | PA preauth/identity R/W | 16 | active identity FK contract; high |
| `mathprep.platform_accounts` | A | PA/NT identity R/W | 911 | active account root; high |
| `mathprep.platform_checkouts` | U | no current direct Go reference | 32 | legacy checkout candidate; low |
| `mathprep.platform_children` | A | PA learning/school R/W | 405 | active bridge to learner; high |
| `mathprep.platform_classes` | A | PA school/learning R/W | 56 | active school graph; high |
| `mathprep.platform_external_identities` | A | PA Google identity R/W | 2 | active OAuth feature; high |
| `mathprep.platform_join_requests` | A | PA school R/W | 36 | notification FK; high |
| `mathprep.platform_learning_answers` | A | PA learning R/W | 263 | active learner API; high |
| `mathprep.platform_learning_capabilities` | A | PA print/read | 34 | active learner API; high |
| `mathprep.platform_learning_drafts` | A | PA learning R/W | 158 | active learner API; high |
| `mathprep.platform_learning_events` | A | PA learning/school inserts | 15 | active learner API; high |
| `mathprep.platform_learning_sessions` | A | PA learning/school R/W | 113 | central active session relation; high |
| `mathprep.platform_license_requests` | A | PA provisioning R/W | 21 | guarded platform contract; high |
| `mathprep.platform_login_intent` | A | PA preauth R/W | 0 | active, but currently empty; high |
| `mathprep.platform_notifications` | A | PA inbox writes/reads | 112 | active notification/outbox parent; high |
| `mathprep.platform_password_recovery_intent` | A | PA recovery R/W | 0 | active, but currently empty; high |
| `mathprep.platform_placements` | A | PA learning/school R/W | 62 | active class bridge; high |
| `mathprep.platform_push_outbox` | A | PA enqueue; NT claim/update | 0 | active durable outbox; high |
| `mathprep.platform_push_preferences` | A | NT R/W | 0 | active, but currently empty; high |
| `mathprep.platform_push_subscriptions` | A | NT R/W | 1 | active device contract; high |
| `mathprep.platform_registration_intent` | A | PA preauth R/W | 0 | active, but currently empty; high |
| `mathprep.platform_schools` | A | PA school/learning R/W | 56 | active school root; high |
| `mathprep.platform_sessions` | A | PA/NT identity reads | 624 | active auth session relation; high |
| `mathprep.platform_staff_requests` | A | PA school R/W | 18 | active staff workflow; high |
| `mathprep.platform_student_access_intent` | A | PA student access R/W | 0 | active, but currently empty; high |
| `mathprep.platform_student_phone_enrollment_intent` | A | PA phone enrollment R/W | 0 | active, but currently empty; high |
| `mathprep.platform_student_profile_link` | A | PA profile-link R/W | 10 | transition/scope triggers; high |
| `mathprep.platform_student_self_profile` | A | PA self-profile R/W | 1 | public-engine bridge; high |
| `mathprep.platform_teacher_classes` | A | PA school/learning R/W | 51 | active class authorization; high |
| `mathprep.platform_tests` | A | PA assessment R/W | 38 | active assessment relation; high |
| `mathprep.platform_trusted_device` | A | PA preauth/recovery R/W | 8 | active device trust relation; high |
| `mathprep.profile_level_history` | U | no current direct Go reference | 0 | profile cluster; external consumer unresolved; low |
| `mathprep.profile_pauses` | U | no current direct Go reference | 0 | profile cluster; external consumer unresolved; low |
| `mathprep.profile_schedules` | U | no current direct Go reference | 4 | profile cluster; external consumer unresolved; low |
| `mathprep.restore_drills` | P | no current restore-drill runner | 0 | operations-design contract; medium |
| `mathprep.retake_authorizations` | P | no enabled assessment service | 0 | assessment subsystem; medium |
| `mathprep.retention_runs` | P | no current retention runner | 0 | operations-design contract; medium |
| `mathprep.schema_migrations` | R | platform startup/readiness ledger | 52 | PA readiness query; high |
| `mathprep.skill_event_exclusions` | P | analytics deferred | 0 | analytics/content subsystem; high |
| `mathprep.skill_events` | P | analytics deferred | 0 | analytics/content subsystem; high |
| `mathprep.skill_prerequisites` | P | no enabled content service | 0 | content subsystem; medium |
| `mathprep.skills` | P | no enabled content service | 8 | content subsystem; medium |
| `mathprep.slo_daily_aggregates` | P | no current SLO runner | 0 | operations-design contract; medium |
| `mathprep.telegram_delivery_attempts` | U | no current direct Go reference | 0 | legacy delivery candidate; low |
| `mathprep.telegram_update_receipts` | U | no current direct Go reference | 0 | legacy delivery candidate; low |
| `mathprep.topics` | A | PA learning/school reads | 8 | active learning FK contract; high |

## Candidates, not confirmed-unused tables

There are **no confirmed unused tables** within the audited project scope.
The following are candidates to retain and investigate, not deletion targets:

* `access_external_identities`, `access_invitations`, and
  `access_recovery_cases`: no direct active-source query was found. The active
  Auth container is ruled out, but potential administrative consumers prevent
  a conclusion. Obtain their inventory and query telemetry before
  reclassification.
* `learner_profiles`, `parent_active_profiles`, `parent_command_receipts`,
  `parent_consents`, `platform_checkouts`, `profile_level_history`,
  `profile_pauses`, `profile_schedules`, `telegram_delivery_attempts`, and
  `telegram_update_receipts`: no active Go SQL path was established. Their
  retained rows and intra-cluster FKs are structural evidence only. Confirm
  provenance from the platform migration source or operational owner.

The `P` groups are planned/disabled subsystems, not unused findings: content,
assessment/pack, analytics, jobs, and operational backup/retention tables.
They remain preserved. CAS relations are implemented but disabled because the
CAS service has no running container and is gated by `cas/AGENTS.md`.

## Reconciliation and verification

A second `pg_class` inventory after exact counts again returned `public=33`,
`mathprep=95`, `total=128`; no structural drift was observed. Row counts can
change while services run and must not be interpreted as DDL drift. The full
catalog extraction used the following sanitized query families:

```sql
SELECT n.nspname, c.relname, c.relkind, pg_total_relation_size(c.oid)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('public','mathprep') AND c.relkind IN ('r','p');

SELECT conrelid::regclass, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE connamespace IN ('public'::regnamespace,'mathprep'::regnamespace);
```

Migration provenance is mixed: `public` is described by
`schema/migrations/000001` onward but has no ledger; `mathprep.schema_migrations`
has 52 applied records, including legacy baseline labels (`0002_schema` through
`0019_web_push_subscriptions`) and canonical mappings (`0020` onward). [DB]
live ledger query; [MIGRATION] `schema/migrations/000094_generation_request_locale.up.sql`,
`000098_billing_foundation.up.sql`, `000099` onward; [DOC]
`deploy/local/docs/platform-schema-source-gaps.md:1-45`.

Recommended next action is the non-destructive reconciliation and privilege
work in `REMEDIATION-EXECUTION.md`. Any future retirement proposal must name
the candidate relation, demonstrate all consumer searches (including Auth and
external operations), state data-retention impact, and receive separate
authorization.
