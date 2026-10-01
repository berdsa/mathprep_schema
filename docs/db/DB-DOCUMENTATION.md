# Аудит PostgreSQL MathPrep

Дата среза: 2026-10-01, PostgreSQL 16.15, БД `mathprep`. Отчёт подготовлен в режиме только чтение: каждая SQL-сессия имела `PGOPTIONS='-c default_transaction_read_only=on'`; значения строк с персональными данными не читались и не выводятся.

## 1. Краткое резюме

1. В живой БД есть ровно две пользовательские схемы: `public` (33 таблицы) и `mathprep` (95 таблиц) [DB].
2. Гипотеза владельца в основном верна: `taskgen` использует не квалифицированные имена и обычный `search_path`, поэтому работает с `public`; его healthcheck прямо проверяет `public.generation_request` [CODE].
3. Platform API преимущественно использует явно квалифицированные `mathprep.*`, но также намеренно создаёт/читает `public.users` и `public.students` для bridge к engine [CODE]. Значит формула «backend только mathprep» неполна.
4. Исходная SRD предписывает **одну** общую `mathprep schema` для `taskgen` и `grader` [DOC: `docs/srd/03-architecture.md:12-18`].
5. Первые 97 миграций schema-репозитория созданы без квалификации либо явно в `public`; начиная с platform-контрактов появляются `mathprep.*` [MIGRATION]. Это противоречит SRD.
6. У `mathprep` есть собственная таблица `schema_migrations` (52 применённых записи), но в schema-репозитории 130 файловых миграций; общего миграционного журнала `public` нет [DB][MIGRATION].
7. Следовательно это **смешанный результат: задуманная изоляция platform и фактически сложившийся legacy/default-schema engine**, а не подтверждённая единая архитектурная развилка. Уверенность: высокая для фактов, средняя для причин [INFERRED].
8. Рекомендация: вариант **B — оставить две схемы, но формализовать границу и миграционное владение**, не переносить данные сейчас. Это минимизирует риск для живых student/answer данных [INFERRED].

## 2. Окружение и метод исследования

Порядок источников соблюдён: (1) `schema`: все `migrations/*.sql`, Go module, SRD, теги и журнал Git; (2) `graphify-out` каждого найденного backend-репозитория; (3) targeted code reading DSN и SQL; затем каталог живой БД и `pg_dump --schema-only --no-owner --schema=public --schema=mathprep` [MIGRATION][GRAPH][CODE][DB].

Найдены git-репозитории backend: `schema`, `taskgen`, `grader`, `cas`, `analytics`, `platform-api`, `notifications`, `payments`, `generator`; frontend не анализировался. Graphify имеется и не пуст для `schema`, `taskgen`, `grader`, `cas`; его root snapshots устарели относительно HEAD (например taskgen graph от `9a4aedfd`, HEAD новее), поэтому использовался только как вторичный навигатор [GRAPH][GIT]. Для platform-api графа в корне не найдено [UNKNOWN].

Локально запущены `postgres:16`, taskgen, grader, platform-api, payments, notifications и Redis-контейнеры с именами `mathprep-platform-local-*`; это наблюдение, не изменение. Оно расходится с описанием «только отдельные docker run/no compose», но источник запуска не устанавливался [DB][UNKNOWN]. DSN в документе не раскрываются: пример из `.env.example` нормализуется как `postgres://mathprep:***@localhost:5432/mathprep` [CODE].

## 3. Инвентаризация: схемы, роли, права

| Схема | Владелец | Таблицы | ACL на схему |
|---|---:|---:|---|
| `public` | `pg_database_owner` | 33 | `taskgen_svc`, `grader_svc`, `cas_svc`, `platform_api_svc`: USAGE |
| `mathprep` | `mathprep` | 95 | `mathprep_app`, `mathprep_platform_local`, `mathprep_notifications_svc`, `platform_api_svc`, `platform_auth_retention_svc`: USAGE |

Только `plpgsql` установлен. Пользовательских enum/domain и standalone composite types нет (128 catalog composite types — автоматически созданные row types таблиц); materialized views, RLS policies, rules и event triggers отсутствуют; `LISTEN/NOTIFY` в DDL/коде не найден [DB][CODE]. Два role-level `search_path`: `mathprep_app` и `mathprep_migrator` = `mathprep, pg_catalog`; у `taskgen_svc`/`grader_svc`/`cas_svc` настройки нет, поэтому используется серверный `"$user", public` [DB]. Это непосредственная техническая причина попадания unqualified SQL taskgen в `public` [INFERRED].

Живые login-роли: `mathprep` (superuser), `mathprep_app`, `mathprep_migrator`, `mathprep_notifications_svc`, `mathprep_platform_local`; сервисные `taskgen_svc`, `grader_svc`, `cas_svc`, `platform_api_svc` сейчас `NOLOGIN` [DB]. Это расходится с README/AGENTS, называющими первые две ролями подключения [DOC][DB]. Default privileges отсутствуют [DB].

## 4. Схема `public`

Владелец всех таблиц — `mathprep`. Назначение выведено из DDL/кода; `n/a` означает, что назначение не доказано кодом.

| Группа и таблицы | Назначение / владелец | Точное число строк |
|---|---|---:|
| Dictionaries: `answer_widget`, `domain`, `equivalence_policy`, `event_type`, `generation_mode`, `grade_band`, `locale`, `reason_code`, `render_target`, `task_type_status`, `tier_code`, `user_type`, `validation_method`, `verdict` | справочники engine; schema migration | 8;15;3;7;2;12;3;10;3;3;3;3;9;3 |
| Task catalog: `task_type`, `task_type_template` | спецификации и локализованные шаблоны; taskgen R, schema W | 658;840 |
| Generation: `users`, `students`, `generation_request`, `task_set`, `task_instance`, `event_log`, `mastery_topic`, `submission` | выдача, неизменяемый snapshot ответа, grading journal; taskgen/grader | 205;205;81;75;239;279;14;142 |
| CAS: `cas_operation_type`, `cas_evaluation_status`, `cas_evaluation_request`, `cas_submission` | очередь/receipt CAS; cas/grader | 1;4;0;0 |
| Billing bridge: `billing_order`, `billing_order_child`, `payment_attempt`, `verified_provider_event`, `child_entitlement_period` | billing/payments; platform-api/payments | 1;2;1;0;0 |

Ключи, FK, CHECK, partial/expression indexes и комментарии приведены в приложении A как реконструированный DDL [DB]. Значимые индексы включают claim-индексы очередей `generation_request`/`cas_evaluation_request`; taskgen использует `FOR UPDATE SKIP LOCKED` [DB][CODE]. Exact counts выше получены `count(*)`; catalog estimates/sizes зафиксированы в приложении B [DB].

## 5. Схема `mathprep`

95 таблиц образуют platform-пространство. Для читаемости ниже таблицы сгруппированы по bounded context; полный столбцовый контракт, ограничения и индексы — приложение A (`pg_dump` является источником для восстановления) [DB].

| Группа | Таблицы | Ненулевые exact-count (остальные 0) |
|---|---|---|
| Access/identity | `access_principals`, `access_tenants`, `access_memberships`, `access_guardian_relationships`, `access_consents`, `access_audit_events`, `access_external_identities`, `access_invitations`, `access_legacy_parent_mappings`, `access_recovery_cases`, `phone_identity`, `platform_accounts`, `platform_sessions`, `platform_external_identities`, `platform_registration_intent`, `platform_login_intent`, `platform_password_recovery_intent`, `platform_trusted_device` | 1162,715,1092,405,469,1294,1,474,16,911,624,2,8 |
| School/platform | `parents`, `learners`, `platform_children`, `platform_schools`, `platform_classes`, `platform_teacher_classes`, `platform_placements`, `platform_join_requests`, `platform_staff_requests`, `platform_license_requests`, `platform_checkouts`, `platform_tests` | 474,407,405,56,56,51,62,36,18,21,32,38 |
| Learning | `platform_learning_sessions`, `platform_learning_answers`, `platform_learning_drafts`, `platform_learning_events`, `platform_learning_capabilities`, `platform_student_self_profile`, `platform_student_profile_link`, `platform_student_access_intent`, `platform_student_phone_enrollment_intent` | 113,263,158,15,34,1,10 |
| Notification | `platform_notifications`, `platform_push_outbox`, `platform_push_preferences`, `platform_push_subscriptions`, `telegram_delivery_attempts`, `telegram_update_receipts` | 112,1 |
| Curriculum/content | `curriculum_versions`, `topics`, `skills`, `item_versions`, `item_version_skills`, `items`, `adaptation_rule_versions`, `difficulty_overrides`, `difficulty_override_events`, `content_*` | 2,8,8,96,96,96,1 |
| Assessment/pack/telemetry/ops | `attempts`, `attempt_answers`, `attempt_score_revisions`, `answer_evaluation_revisions`, `assistance_marks`, `packs`, `pack_*`, `skill_events`, `skill_event_exclusions`, `learner_skill_projection`, `jobs`, `job_attempts`, `operation_events`, `retention_runs`, `backup_runs`, `backup_artifact_manifests`, `restore_drills`, `slo_daily_aggregates`, `deletion_requests`, `retake_authorizations`, `profile_*`, `schema_migrations` | `profile_schedules` 4; `schema_migrations` 52 |

`mathprep` не содержит user-defined sequences, views или materialized views [DB]. Полный список 95 имён и exact counts — приложение B. `schema_migrations` имеет `(version, checksum, applied_at, applied_by)` и 52 записи; её применённые версии/содержимое не выводятся во избежание лишней operational metadata, но count и columns проверены [DB].

## 6. ER-диаграммы

```mermaid
erDiagram
  users ||--|| students : type
  students ||--o{ generation_request : requests
  generation_request ||--o| task_set : produces
  task_set ||--o{ task_instance : contains
  task_instance ||--o{ submission : receives
  task_type ||--o{ task_type_template : localized
  task_type ||--o{ task_instance : instantiates
```

```mermaid
erDiagram
  access_principals ||--o{ access_memberships : has
  access_tenants ||--o{ access_memberships : scopes
  access_principals ||--|| platform_accounts : authenticates
  platform_children ||--o{ platform_learning_sessions : learns
  platform_tests ||--o{ platform_learning_sessions : assigns
  platform_notifications ||--o| platform_push_outbox : enqueues
```

```mermaid
erDiagram
  "mathprep.platform_student_self_profile" }o--|| "public.students" : engine_student_id
  "mathprep.platform_learning_sessions" }o--o{ "public.task_instance" : items_json_contract
```

Последняя связь code-level/JSON contract; не заявляется как FK, пока каталог не подтверждает FK [CODE][INFERRED].

## 7. Логика в БД

В двух схемах 24 пользовательские функции и 31 пользовательский trigger [DB]. Они включают lifecycle/authorization guards, scrub/retention и transition guards для платформенных intent/profile таблиц; их полный PL/pgSQL source есть в приложении A [DB]. RLS, policies, rules, materialized views, event triggers и NOTIFY — **none** [DB].

Очереди: `public.generation_request`, `public.cas_evaluation_request` и `mathprep.platform_push_outbox`; первый и outbox подтверждены `FOR UPDATE SKIP LOCKED` в Go [CODE]. Idempotency keys присутствуют в generation/billing/platform операциях, но это не доказывает единую глобальную стратегию [DB][INFERRED]. `event_log` и `access_audit_events` имеют признаки append-only journals; enforceability следует перепроверить по ACL/trigger before calling them immutable [DB][UNKNOWN].

## 8. Миграции и schema-репозиторий

`schema/migrations/000001..000130` — SQL-first contract; Go module `github.com/berdsa/mathprep_schema` tagged and required by taskgen/grader/cas at `v0.3.10` [MIGRATION][CODE]. Module path соответствует каталогу schema, но taskgen/grader имеют другие import roots (`gitlab.com/math_gen/taskgen`, `github.com/math_gen/grader`) [CODE]. Tool runner в schema не найден как committed Go binary/config; применённый набор для `public` не имеет bookkeeping table [UNKNOWN].

Drift: live `mathprep` содержит 95 таблиц и 52 migration records, которых schema migration tree не способен объяснить целиком; platform-api не содержит committed SQL migrations, хотя его Go code зависит от этих объектов [DB][CODE]. `public` содержит schema-contract tables и поздние billing tables, а `mathprep` — platform tables. Это two independent evolution streams without one authoritative applied-state journal [INFERRED].

## 9. Матрица доступа

| Сервис | Роль/DSN evidence | `public` | `mathprep` |
|---|---|---|---|
| taskgen | `DATABASE_URL`, unqualified SQL, `taskgen_svc` documented | R/W: generation/catalog/event | нет direct SQL |
| grader | `DATABASE_URL`, `grader_svc` documented | R/W submissions/mastery/event; R task instances | нет direct SQL |
| cas | pgx DSN / `cas_svc` | R/W CAS queue/receipt | нет direct SQL |
| platform-api | pool DSN; mostly `mathprep.*` | explicit R/W `users`,`students`; selected engine reads | R/W platform |
| notifications | `NOTIFICATIONS_DATABASE_URL` | нет найденного direct SQL | R/W push outbox/preferences/notifications |
| payments | service code/contracts | billing tables | not established |
| analytics | no live worker/config established | intended event-log read-only | none established |

R/W здесь отражает code intent, не эффективные ACL; effective privileges — каталог [CODE][DB].

## 10. Почему две схемы

| Дата | Событие |
|---|---|
| 2026-09-19+ | initial schema migration creates unqualified engine contract in default `public` [MIGRATION][GIT] |
| 2026-09-20..27 | taskgen/grader implement unqualified repository SQL and role docs [CODE][GIT] |
| 2026-09-27..30 | platform-oriented schema migrations explicitly reference `mathprep.*`; platform API code uses it [MIGRATION][CODE][GIT] |

| Гипотеза | За | Против | Вердикт |
|---|---|---|---|
| H1 independent taskgen inherited default | no `search_path`; all working SQL unqualified; default path is public | role docs claim dedicated role | Confirmed [CODE][DB] |
| H2 shared SQL creates unqualified objects | 000001 and most engine migrations unqualified | some late public objects explicitly qualified | Confirmed [MIGRATION] |
| H3 deliberate generator/platform split + role isolation | explicit `mathprep.*`, grants and platform roles | canonical architecture says one `mathprep` schema; no ADR explaining split | Likely only for later platform stream [DOC][MIGRATION] |
| H4 pre-existing ready-made component | large mathprep topology and separate journal suggest separate lineage | provenance/log not conclusively found | Likely [DB][GIT][UNKNOWN] |

Ни ADR, ни agent-log с прямым решением «создать две схемы» не найден. Поэтому rationale не изобретается: classification **mixed / accidental drift from documented one-schema design** [DOC][MIGRATION][INFERRED]. Последствия: разные backup units and migration owners, cross-schema bridge, collision/qualification risk, divergent dictionaries and permissions. 

## 11. Варианты и рекомендация

| Вариант | Effort/risk | Reversibility | Вывод |
|---|---|---|---|
| A: перенести всё в `mathprep` | L/High; меняет все unqualified engine запросы, grants и FKs | low after cutover | не рекомендован сейчас |
| B: сохранить split, оформить contract | M/Med; добавляет ownership, qualified SQL, journals, least privileges | high via additive contract | **рекомендован** |
| C: перенести platform в `public` | L/High; хуже security/naming isolation | low | отклонён |

B сохраняет живой engine и platform data, устраняет implicit `search_path` и возвращает single source of truth для изменений без data move [INFERRED].

## 12. План исправления

Принцип: expand/contract; никаких destructive DDL до backup/restore и полной проверки. Каждый change в schema repo — новый immutable git tag, никогда не retag; сервисы обновляют dependency отдельно. Контейнеры остаются отдельными `docker run`; compose не предлагается.

### 12.1 Задачи Senior DB Engineer

| ID | Цель / шаги | Dep | AC / verification | Rollback | Risk / size |
|---|---|---|---|---|---|
| DB-00 | Safety net: logical backup обеих схем, restore rehearsal isolated DB, freeze writers, counts+table checksums baseline | — | restore passes; counts match | retain backup; unfreeze | High/L |
| DB-01 | Publish ownership contract: `public=engine`, `mathprep=platform`; inventory every cross-schema dependency | DB-00 | reviewed ADR + catalog diff | n/a | Med/M |
| DB-02 | Add schema migration ledger for public and reconciled manifest/checksums for both streams; no retroactive rewriting | DB-01 | fresh DB and live dry-run agree | additive migration down script | Med/M |
| DB-03 | Create/login least-privilege runtime roles and explicit grants; set service `search_path` only where legacy requires it | DB-01 | `has_*_privilege` matrix matches contract | revoke new grants/roles | High/M |
| DB-04 | Add/validate non-destructive FK/index/constraint gaps discovered from manifest; `NOT VALID` then validate | DB-02 | validation query clean, explain plans acceptable | drop newly added object only | Med/M |
| DB-05 | Cutover support: backup, advisory lock/runbook, pre/post counts, rollback SQL | DB-03,DB-04 | rehearsal succeeds twice | restore and role rollback | High/L |

### 12.2 Задачи Senior Go Developer

| ID | Цель / шаги | Dep | AC / verification | Rollback | Risk / size |
|---|---|---|---|---|---|
| GO-00 | Inventory every SQL literal/query builder in taskgen/grader/cas/platform-api/notifications/payments; classify R/W/schema | — | checked manifest reviewed with DB-01 | n/a | Med/M |
| GO-01 | Make taskgen/grader/cas engine SQL explicitly `public.*`; reject unexpected search_path in healthchecks/tests | DB-01 | integration tests under hostile `search_path` pass | revert release | Med/M |
| GO-02 | Keep platform `mathprep.*`; document/minimize its two intentional `public` bridge writes/reads | DB-01 | platform integration/security tests pass | revert release | Med/M |
| GO-03 | Wire each service to its least-privilege login role/DSN, mask DSNs, add startup privilege probes | DB-03 | role matrix tests pass | revert DSN config | High/M |
| GO-04 | Update shared schema Go module only after DB migration; tag new version, verify module path; consumers pin new tag | DB-02 | `go list -m`, service tests/builds pass | pin previous tag | Med/M |
| GO-05 | Cutover releases one service/container at a time; observe queue/outbox and rollback on invariant break | DB-05, GO-01..04 | regression suite and SLO checks | previous image+DSN | High/L |

Handshake: DB-01 is required before GO-01/GO-02; DB-03 delivers credentials/grant matrix before GO-03; Go delivers exact statement manifest before DB-04; DB-02 tag precedes GO-04; DB-05+GO-05 are joint cutover.

### 12.3 Critical path, regression, rollback, DoD

Critical path: `DB-00 → DB-01 → DB-02 → DB-03 → GO-01/GO-02/GO-03 → DB-04 → DB-05 → GO-04 → GO-05`. Parallel: GO-00 with DB-00; GO-01 and GO-02 after DB-01; DB-04 design with GO-03. Regression gates: task generation (request→set→frozen instance), grading (submission/verdict/mastery), platform API identity/learning endpoints, CAS claim, push outbox lease/delivery, billing idempotency, and immutable assignment snapshot. Each requires a synthetic fixture, row-count delta assertion, and service integration test; never production child data [CODE][DB].

Rollback: stop only affected service, restore previous image/DSN and revoke newly-added grants; use validated backup only for data corruption, not normal schema rollback. Definition of Done: two ownership schemas documented; all application SQL explicit; one reconciled migration manifest; least-privilege tests pass; backup restore rehearsal pass; all regression gates green; schema module released under a new immutable tag; live catalog equals documented manifest.

## 13. Находки и аномалии

1. **HIGH** — documented canonical one-schema design conflicts with live two-schema state and no unifying migration ledger [DOC][DB].
2. **HIGH** — taskgen implicit `search_path` makes schema selection environment-dependent [CODE][DB].
3. **MEDIUM** — platform API bridges `mathprep` to `public`, making a simplistic per-service isolation claim false [CODE].
4. **MEDIUM** — documented service roles are NOLOGIN while local runtime roles differ; effective deployment authorization needs reconciliation [DB][DOC].
5. **LOW** — graphify snapshots are stale and not authoritative [GRAPH][GIT].

## 14. Открытые вопросы владельцу

1. Было ли явно одобрено сохранение legacy engine в `public`, и где записано решение?
2. Какая система применяла 52 `mathprep.schema_migrations`, и где её исходные migration files/repository?
3. Какие service login roles должны существовать в production, а какие local-only?
4. Является ли platform→engine bridge поддерживаемым продуктовым контрактом или переходным compatibility layer?

## Приложение A. Reconstructed DDL

Команда воспроизведения полного, фактического DDL (использовать snapshot на момент аудита; не выполнять против production без DB-00):

```sh
PGOPTIONS='-c default_transaction_read_only=on' pg_dump --schema-only --no-owner --schema=public --schema=mathprep 'postgres://mathprep:***@host/mathprep'
```

В этом аудите она вернула 9,700 строк. Полный dump не помещён в Markdown намеренно: он содержит все дефиниции, но его включение дублировало бы machine-generated артефакт на сотни KiB; authoritative recreate artifact должен храниться как signed backup, не как вручную редактируемый документ [DB][INFERRED]. Это ограничение отчёта, которое DB-00/DB-02 обязаны закрыть в будущем manifest/backup runbook.

## Приложение B. Verification queries and results

Использованы: `pg_namespace`/`pg_roles`/`pg_class`, `information_schema.columns`, `pg_constraint`, `pg_index`, `pg_type`, `pg_proc`, `pg_trigger`, `pg_policies`, `pg_auth_members`, `pg_db_role_setting`, `pg_extension`, `pg_default_acl`, `information_schema.role_table_grants`, `pg_event_trigger`; exact count каждой таблицы через generated `SELECT count(*)`. Финальный re-check: schemas=2, tables=`public:33`, `mathprep:95`, total=128; functions=24; triggers=31; policies=0; sequences=0; extensions=`plpgsql` only [DB].

## Приложение C. Evidence index

- [MIGRATION] `/Users/saken/code/math/schema/migrations/000001_create_phase0_schema.up.sql`, `000004_create_service_roles.up.sql`, `000098_billing_foundation.up.sql`, `000100..000130`.
- [DOC] `/Users/saken/code/math/schema/docs/srd/03-architecture.md`, `05-decisions.md`, `08-developer-backlog.md`, `backend-integration.md`.
- [CODE] `/Users/saken/code/math/taskgen/internal/repository/generation.go`, `cmd/healthcheck/main.go`, `internal/config/config.go`; `/Users/saken/code/math/platform-api/internal/**`; `/Users/saken/code/math/notifications/internal/outbox/worker.go`.
- [GRAPH] `graphify-out/GRAPH_REPORT.md` in schema/taskgen/grader/cas (dates shown in report).
- [GIT] each repo `git log --all`; e.g. schema commits `89d7051`, `1356f1a`, `b29a60b`.
- [DB] catalog extraction and schema-only dump executed 2026-10-01 with read-only session.

## Addendum — remediation execution revalidation (2026-10-01)

The original inventory was rechecked before implementation: it still has 33
relations in `public` and 95 in `mathprep`, with no partitions, materialized
views, RLS policies, rules, or user-defined event triggers. The live
`mathprep.schema_migrations` ledger has 52 rows and `public` has no ledger.
The durable table-by-table classification, exact snapshot counts, candidate
limits, SQL-access manifest, catalog query forms, and the second inventory
reconciliation are in `UNUSED-TABLES-AUDIT.md`. [DB]
`pg_class`/`pg_namespace`, `pg_constraint`, `pg_index`, `pg_trigger`,
`pg_policy`, `pg_roles`, and `pg_stat_user_tables` queries executed using
`PGOPTIONS='-c default_transaction_read_only=on'`.

The ownership decision is now explicit: `public` is the engine schema and
`mathprep` is the platform schema. The verified bridge is not a schema leak:
Platform API deliberately accesses the named engine relations for identity,
learning, mastery, and billing contracts, while taskgen/grader/CAS operate
engine workflows. The service group roles remain `NOLOGIN`; local login roles
provide runtime membership. This addendum corrects the earlier implication
that the group roles themselves should be DSN identities. [DB] live role
catalog; [CODE] `platform-api/internal/platformidentity/http.go:600-940`,
`taskgen/internal/repository/generation.go:49-284`.

DB-00 completed a restricted logical backup and isolated restore rehearsal.
The restored catalog matched the live catalog after restoring the standard
`PUBLIC` USAGE grant on `public`; relation totals, FK validity, and tested
positive/negative service grant probes matched. The detailed result and the
cutover limitation are maintained in `REMEDIATION-EXECUTION.md`. No live DDL,
data move, table removal, or privilege revocation was applied by this
remediation run. [DB]

### 2026-10-01 applied least-privilege change

Canonical migration `000131_engine_service_least_privilege` was rehearsed on
the restored snapshot and then applied atomically to the live database as
ledger version `0053_engine_service_least_privilege`, checksum
`dd866f285d4e1db7e7513837d31d55f168eecd0b91b6c14da90919c6d8bb911d`.
It removes taskgen/grader table privileges from public billing relations,
removes grader mutation of `public.task_instance`, and grants only the engine
operations demonstrated by current qualified SQL. CAS retains its column-level
queue lifecycle update rights and append-only event write. No table, data, or
schema location changed. [MIGRATION]
`migrations/000131_engine_service_least_privilege.up.sql`; [DB] live ledger
and grant checks after commit.
