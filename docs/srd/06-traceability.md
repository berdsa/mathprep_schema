# 06 — Traceability, Glossary, Stakeholders, Open Items

## Glossary — carried forward from `00-scope-lock.md` (single normative copy per quality-gate rule)

| Term | Definition |
|---|---|
| **Тип задания (task type)** | Параметризованный шаблон с детерминированно вычислимым верным ответом и объявленным методом валидации |
| **Инстанс (item instance)** | Конкретная задача, полученная подстановкой разрешённых параметров; хранит разрешённые параметры, не только seed |
| **Пространство инстансов `\|S\|`** | Количество различимых инстансов в рамках одного tier'а при действующих ограничениях отбраковки |
| **GeneratorSpec** | Нормативное описание генерации: переменные, ограничения, retry-cap, fallback-пул |
| **Verification oracle** | Независимая проверка: подстановка ответа обратно, единственность, каноническая форма, невырожденность |
| **`equivalence_policy`** | `STRICT-FORM \| EQUIV-CLASS \| CAS-EQUIV`, без дефолта |
| **UNPARSEABLE** | Вердикт «не разобрано»; не попытка, не влияет на mastery |
| **Wave** *(переименовано этим ходом)* | Волна раскатки по классам/предметным полосам. Заменяет прежнее «Tier» в этом смысле |
| **Tier** (`T1`/`T2`/…) | Только уровень сложности параметров внутри одного типа — единственный смысл, с этого хода |
| **NotationProfile** | Структурный объект локали: разделитель, группировка, пунктуация, имена функций, глифы |
| **Misconception-тег** | Идентифицированная типовая ошибка → дистрактор MCQ |
| **`GENERATION_REQUEST`** *(new)* | Строка job-очереди: заявка на генерацию набора заданий, обрабатываемая воркером асинхронно |
| **`EVENT_LOG`** *(new)* | Append-only журнал событий, основа для будущей (отложенной) аналитики |

## Карта стейкхолдеров
Unchanged from prior pass — Ученица 3 класса, Ученица 6 класса, Оператор-методолог, Бэкенд-инженер, QA, Владелец продукта. Not restated in full here to avoid duplication; see prior-pass content, nothing about the people or their goals changed this turn — only the system built for them did.

## Реестр допущений — consolidated

| ID | Допущение | Owner |
|---|---|---|
| ASM-01 | task-bank-generator расширяется, не заменяется | Оператор |
| ASM-02 | Wave A = 3 и 6 класс (порядок первого прохода, не граница скоупа — см. SCOPE-AMD-01) | Оператор |
| ASM-03 | Контентная локаль — `ru-KZ` | Оператор |
| ASM-04 | *(снято SCOPE-AMD-01 — вуз больше не вне скоупа бэклога)* | — |
| ASM-05 | Render targets Wave A/B — `plaintext`, `unicode-math` | Инженер |
| ASM-06 | `STRICT-FORM` по умолчанию для «сократи»/«упрости» | Методолог |
| ASM-07 | Контрольные суммы `bt.md` и др. снимаются оператором локально | Оператор |
| ASM-08 | Согласие опекуна удовлетворено статусом оператора как законного представителя, в рамках семейного пилота | Оператор/Legal |
| ASM-09 | Существующий VPS достаточен для семейного пилота, новый sub-processor не вводится | Оператор |
| ASM-10 *(new)* | Bot/Web общаются с сервисами через тонкий HTTP, не напрямую с БД | Инженер/Оператор |
| ASM-11 *(new)* | Worker внутри `mathprep-taskgen` — горутина в том же бинарнике, не отдельный деплоймый сервис | Инженер |
| ASM-12 *(new)* | Общий Go-модуль `mathprep-schema` — единственное разрешённое исключение из «нет общего кода между сервисами» | Оператор (может наложить вето) |

## Реестр открытых вопросов — consolidated

| ID | Вопрос | Дефолт | Owner |
|---|---|---|---|
| OPEN-01 | Замороженная редакция учебной программы | Типы остаются `[UNVERIFIED]`/DRAFT | Владелец продукта |
| OPEN-02 | Правовое основание за пределами семейного пилота | fail-closed gate | Legal |
| OPEN-03 | Допустим ли внешний AI-провайдер | authoring-time HYBRID-AI only (ADR-005) | Legal/Security |
| OPEN-04 | Порог расхождения эмпирической/заявленной сложности | Статистика считается, авто-флаг не выставляется | Владелец продукта |
| OPEN-05 | Минимальный `\|S\|`/cooldown | `≥200` / 30 дней | Методолог |
| OPEN-06 | CAS security boundary sign-off | CAS не регистрируется **— теперь блокирует конкретные фазы бэклога, не просто «когда-нибудь»** (SCOPE-AMD-01) | Backend |
| OPEN-07 | Сверка ERD/схемы со старым каталогом task-bank-generator | Ни одна миграция не пишется до закрытия | Backend |
| OPEN-08 *(new, finding G)* | Поведение `MASTERY_TOPIC` при переходе ученицы в следующий класс | Не определено, не решается по умолчанию | Методолог |

## Traceability matrix

| Business goal | FR | Component |
|---|---|---|
| BG-01 "immediate, trustworthy verdict" | FR-002, FR-003, FR-004 | `mathprep-schema`'s validation pipeline, consumed by `mathprep-grader` |
| BG-02 "extend catalog without regressions" | FR-005, FR-006 + golden tests | `mathprep-taskgen` registry, defect-remediation job |
| BG-03 "no student misgraded due to input-format friction" | FR-004 + input contract | `mathprep-grader` Stage-1 parse |
| BG-04 "weak topics get more practice" | FR-001 | `mathprep-taskgen` weighting (algorithm not yet specified) |
| BG-05 "no request lost, none double-processed" *(new)* | FR-007 | `mathprep-taskgen` job queue |
| BG-06 "complete history for future analytics, without blocking it" *(new)* | FR-008 | `EVENT_LOG`, written by both `mathprep-taskgen` and `mathprep-grader` |

No orphan FRs (six map to six goals); no orphan ERD entities (`USERS`, `STUDENTS`, `GENERATION_REQUEST`, `TASK_TYPE`, `TASK_SET`, `TASK_INSTANCE`, `SUBMISSION`, `MASTERY_TOPIC`, `EVENT_LOG` — all reachable from at least one FR above).

## Definition of Done
**Per task type:** `DRAFT → GATED` (oracle 1000/1000 both directions, golden fixture committed) `→ FINAL` (ID reconciled non-PROVISIONAL against `MISS-02`, curriculum ref confirmed against `MISS-01`). Only `FINAL` (or, within the family pilot only, `GATED` per ASM-08) types compile into a service's active registry.

**Per service release:** all Gherkin scenarios (FR-001…008) automated and green in that service's own CI; golden tests green for every type it owns; its own STRIDE-boundary mitigations implemented; data-governance gates closed for family-pilot scope.

## Migration / rollout / rollback
Rollout: each service has its own CI/CD to the shared VPS; `mathprep-taskgen`'s registry loads only `FINAL`/`GATED` types. Rollback trigger (numeric, unchanged): `unparseable_rate > 25%` for a newly-registered type within its first 100 submissions → config-only allowlist change disables that `type_id`, no redeploy. Migration: additive-only until `OPEN-07` closes; owned solely by `mathprep-schema` — neither `mathprep-taskgen` nor `mathprep-grader` ships its own migration files (this was implicit before, made explicit now that there are three repos that could otherwise each try to own a piece of the schema).
