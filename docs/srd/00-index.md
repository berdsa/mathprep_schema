# 00 — Индекс артефактов трека `math-task-catalog`

Обновляется перед завершением каждого хода. Статусы: `NOT STARTED → DRAFT → GATED (прошёл quality gate) → FINAL`. `BLOCKED` фиксируется с ID блокирующего вопроса.

| ID | Артефакт | Статус | Примечание |
|---|---|---|---|
| ART-00 | `00-index.md` | RUNNING | Этот файл |
| ART-01 | `00-scope-lock.md` | FINAL (подтверждён оператором), с **SCOPE-AMD-01** поверх |
| ART-02 | `01-current-state.md` | FINAL (подтверждён оператором) |
| ART-03 | `02-requirements.md` | DRAFT — добавлены FR-007 (job queue), FR-008 (event log) |
| ART-04 | `00-conventions.md` | DRAFT — заблокирован от FINAL пунктом OPEN-07 (сверка со старым каталогом типов); добавлены dictionary-таблицы |
| ART-05 | `backend-integration.md` | DRAFT — переписан под 3 независимых сервиса |
| ART-06 | `data-governance.md` | DRAFT (семейный пилот закрыт; более широкий rollout — OPEN-02) |
| ART-07 | Спеки типов-образцов | DRAFT — 5 из ~150+ типов всего каталога (см. `07-task-type-specs-exemplars.md`) |
| ART-08 | `03-architecture.md` | DRAFT — архитектура на 3 репозитория |
| ART-09 | `04-nfr-risk-ops.md` | DRAFT |
| ART-10 | `05-decisions.md` | DRAFT — ADR-001…007, ADR-001 помечен Superseded |
| ART-11 | `06-traceability.md` | DRAFT |
| ART-12 | `08-developer-backlog.md` | DRAFT — новый, фазированный бэклог для Go-разработчика |

## Реестр репозиториев (введён этим ходом, см. ADR-006)

| Репозиторий | Назначение | Статус |
|---|---|---|
| `mathprep-schema` | DDL-миграции, справочники, версия схемы, минимальный shared Go-пакет с общими enum/структурами строк | NOT STARTED |
| `mathprep-taskgen` | Генерация инстансов заданий + назначение студенту (job-worker на Postgres) | NOT STARTED |
| `mathprep-grader` | Приём и валидация ответов | NOT STARTED |
| `mathprep-analytics` | **Поздняя фаза.** Роллапы поверх журнала событий | NOT STARTED — не начинать раньше `08-developer-backlog.md` Фазы «Analytics» |

## Реестр допущений и открытых вопросов — сводный, обновлён

См. `06-traceability.md` §Open Questions для полного списка. Новые в этом ходе: **ASM-10** (транспорт Bot/Web↔сервисы остаётся тонким HTTP, не прямой доступ к БД), **SCOPE-AMD-01** (вуз возвращён в скоуп бэклога, CAS boundary — обязательная фаза).
