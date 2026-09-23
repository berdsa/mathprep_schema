# 00 — Scope Lock

## SCOPE AMENDMENT — SCOPE-AMD-01 (этот ход)

Директива оператора: «go to the next tasks one, by one each for all types from 1st to the university grade» отменяет прежнее ограничение скоупа до 3 и 6 класса (ASM-02) и прежний вывод вуза за скоуп (OOS-04).

**Новое состояние:** весь каталог, 1 класс → вуз, входит в бэклог реализации (`08-developer-backlog.md`), обрабатывается последовательно в порядке учебной программы, тип за типом, с многоступенчатым подтверждением перед каждым следующим типом.

**Не отменяется этой поправкой:**
- Юридическое основание (`OPEN-02`) остаётся ограничено семейным пилотом (`ASM-08`); расширение на других пользователей по-прежнему требует отдельного согласия.
- Локаль Tier-контента (`ASM-03`, `ru-KZ`) не меняется.
- Тип не покидает `DRAFT`/`GATED` без независимой сверки с учебной программой (`OPEN-01`) — включение в скоуп бэклога ≠ включение в производство.

**CAS prerequisite status:** university и часть Grade 10–11 требуют CAS (символьные вычисления: производные, интегралы, факторизация). Изолированный CAS evaluator был обязательной фазой до начала этих типов; эта инфраструктура реализована, а `OPEN-06` подписан Ken 2026-09-22 (см. `backend-integration.md` §3 и `taskgen/docs/signoffs/OPEN-06.md`). Каждый CAS-backed тип по-прежнему требует собственного полного Confirmation Gate.

## SCOPE AMENDMENT — SCOPE-AMD-02 (this pass)

Operator directive: task content must support Kazakh (`kk-KZ`), Russian (`ru-KZ`), and English (locale code TBD, `en-US` assumed pending confirmation), with the data model open to adding further locales later without a schema change.

**Overrides:** `ASM-03` (content locale fixed to `ru-KZ` only) and `OOS-08` (`kk-KZ` explicitly out of scope) are both superseded. English was never previously in scope at all — this is new, not a re-opening.

**What this changes, concretely:**
- A type's `Template` field moves from a single string to a per-locale map. Every already-`GATED` type needs retrofitting, not just new ones going forward.
- `NotationProfile` needs real entries for `kk-KZ` and the chosen English locale code, not just `ru-KZ`. Kazakh notation conventions (decimal separator, function names, GCD/LCM terms) are **not sourced anywhere in this SRD** and must not be invented — confirm with a real curriculum source or the operator directly.
- `EXACT-RAT`/`TOL`-class validation (anything decimal-separator-sensitive) becomes locale-aware in `pkg/core` — currently assumes one fixed convention.
- A locale-selection mechanism is needed: `STUDENTS.preferred_locale` plus an optional per-request override, neither of which exists in the ERD yet.
- Translated templates carry the same correctness stakes as `G4-NUM-005`'s HYBRID-AI narratives — a bad translation can change what a problem is actually asking. Same discipline applies: authored once per template, reviewed once, not generated per-instance.

**Does not change:** the underlying dictionary-driven locale architecture already anticipated this (`00-conventions.md` §6 already reserved `kk-KZ` as a dictionary value) — this amendment activates and extends a pattern that was already designed for, not one invented from scratch.



Слово «Tier» ранее использовалось в двух смыслах одновременно: (а) волна раскатки по классам, (б) уровень сложности параметров внутри одного типа (`T1`/`T2` картриджа). Разведено:

- **Wave** — волна раскатки по классам/предметным полосам (замена бывшего «Tier 1/2/3» в старом смысле).
- **Tier** (`T1`, `T2`, …) — остаётся только за уровнем сложности внутри одного типа, как в картридже.

## SCOPE AMENDMENT — SCOPE-AMD-03 (this pass)

**Finding this responds to:** the catalog in active use (`math-task-catalog_updated.md`, operator-supplied, AI-generated) is structured entirely on US Common Core (domain codes `OA/NBT/NF/MD/RP/NS/EE/F/SP`; Grades 9–11 labeled by US course name, not grade number). ~30 task types were implemented and marked `GATED` against it before this was caught; none yet served to a real student (confirmed by operator). Separately: `task_type` was found to have **zero rows** in the live database — the DB-persistence side of the registry was never actually wired, a gap in the original Phase 1 prompts, not an agent failure (see `11-catalog-regrade-and-e2e-audit.md`).

**Decision (operator, this pass): keep every already-generated task type — do not discard or rebuild from scratch.** Re-assign each one to its correct grade under Kazakhstan/Russia curriculum convention where knowable, falling back to broader international consensus where not, and never leave several grades grouped under one ID band (the earlier `G1-2` combined band is also corrected by this pass). Catalog entries not yet implemented are tracked in `docs/BLOCKED.md`, not silently dropped.

`OPEN-01` (frozen Kazakhstani curriculum edition) remains unresolved — neither operator nor model has a verifiable source. The Russian ФГОС standard is treated as the more defensible primary reference where Kazakhstan-specific detail is unavailable, given shared post-Soviet educational heritage and this project's own `ru-KZ` locale — this is a reasoned methodological choice, not a verified fact, and every grade placement not traceable to an actual source stays marked as such rather than presented as authoritative.



| Поле | Значение | Тег |
|---|---|---|
| DOMAIN | Автоматическая генерация учебных заданий по математике и их автоматическая проверка | `[SOURCED: REF-01, REF-02]` |
| PRIMARY DELIVERABLE | (а) полный каталог типов заданий по картриджу `automated-item-generation`; (б) фазированный бэклог для Go-разработчика; (в) готовые к скачиванию файлы по главам | `[SOURCED: OPR]` |
| SCOPE WAVE A | Grade 3, Grade 6 (первый рабочий срез — дочери оператора) | `[ASSUMPTION: ASM-02]`, сохранён как порядок первого прохода, не как граница скоупа |
| SCOPE WAVE B/C/D | Всё остальное — Grade 1–2, 4–5, 7–9, 10–11, вуз — **теперь в скоупе бэклога** | `SCOPE-AMD-01` |
| TARGET STACK | **Go + PostgreSQL. Kafka не используется.** Три независимых Go-репозитория + общий Postgres-инстанс, отдельная схема | `[SOURCED: OPR]` |
| SERVICE TOPOLOGY | `schema` (миграции+справочники), `taskgen` (генерация+назначение), `grader` (валидация ответов), `analytics` (поздняя фаза) — отдельные git-репозитории, отдельные деплоймые артефакты | `[SOURCED: OPR]`, см. ADR-006 |
| INTEGRATION MECHANISM | Job-очередь на PostgreSQL (`GENERATION_REQUEST`, `FOR UPDATE SKIP LOCKED`), не брокер сообщений | `[DERIVED]` из «takes tasks from db» + CON-04 |
| END USERS | См. §5 (ниже, без изменений) | `[DERIVED]` |
| AUTHORITATIVE SOURCES | REF-01 (справочный), REF-02 (методологический). Учебная программа РК — не подана | `[UNVERIFIED]` |
| DELIVERY CHANNELS | Telegram-бот → документ с заданиями; QR → веб-страница самопроверки | `[SOURCED: OPR]` |
| REGULATORY REGIME | РК; субъекты данных — несовершеннолетние, семейный пилот | `[SOURCED: OPR]` |
| DOCUMENT LANGUAGE | `ru-RU` | `[SOURCED: OPR]` |

## 2. В скоупе (обновлено)

Пункты SC-01…SC-10 из предыдущего хода — без изменений. Добавлено:

| ID | Пункт |
|---|---|
| SC-11 | Job-очередь генерации на Postgres: заявка → обработка воркером → запись инстанса и назначения |
| SC-12 | Append-only журнал событий (`EVENT_LOG`), пишется с первой фазы, не ретроактивно |
| SC-13 | Разделение сущностей `USERS`(с типом) / `STUDENTS` вместо плоской студенческой таблицы |
| SC-14 | Фазированный бэклог реализации от БД до вуза, с обязательными точками подтверждения |

## 3. Вне скоупа (обновлено)

OOS-01…OOS-03, OOS-05…OOS-07 — без изменений. **OOS-04 (вуз) отменён SCOPE-AMD-01.** Добавлено:

| ID | Пункт | Причина |
|---|---|---|
| OOS-08 | `kk-KZ` локаль | По-прежнему `ASM-03`, не затронуто этим ходом |
| OOS-09 | Аналитический сервис-потребитель журнала (`analytics`) до завершения основной функциональности | Прямая директива оператора этого хода |
| OOS-10 | Использование брокера сообщений (Kafka и т.п.) | Финальная явная строка оператора «Stack: go, postgres» |

## 4–7. Глоссарий, карта стейкхолдеров, реестр допущений, реестр открытых вопросов

Без изменений по содержанию — перенесены в `06-traceability.md`, чтобы не дублировать в двух файлах (правило quality gate: не переопределять то, что уже определено в другом артефакте). Новые пункты (`ASM-10`, `SCOPE-AMD-01` как формальная запись) добавлены там же.
