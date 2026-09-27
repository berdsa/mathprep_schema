# Local platform integration plan

## Scope

Add the request-level locale preference needed by taskgen. `generation_request.locale` is persisted caller preference, defaults to `ru-KZ`, and remains distinct from the locale frozen on generated task instances. The locale column references the canonical `locale` dictionary and accepts the currently supported development codes `ru-KZ`, `kk-KZ`, and `en-US`.

## Specification decision

The existing canonical dictionary description in `docs/srd/00-conventions.md` §6 and seed migration `000002` list only `ru-KZ` and describe `kk-KZ` as reserved. `docs/srd/00-scope-lock.md` SCOPE-AMD-02 supersedes that state by explicitly bringing `kk-KZ` into development scope and assuming `en-US` pending product confirmation. Per the integration directive, migration `000094` will add `kk-KZ` and `en-US` to the locale dictionary; the historical seed migration will remain unchanged. English remains a development assumption pending product confirmation. This change makes no claim of language review, curriculum validation, or notation/translation readiness.

## Changes

1. Add `000094_generation_request_locale` to seed `kk-KZ` and `en-US`, add non-null `generation_request.locale` with default `ru-KZ` and a foreign key to `locale(code)`, and constrain request preferences to the three currently supported codes. Add a matching down migration.
2. Add the supported locale constants and `Locale` field to the shared `core.GenerationRequest` row.
3. Record and verify the migration against a separate synthetic database in the existing Postgres container; do not alter the existing `mathprep` database.
4. Append evidence to `docs/agent-log.md`, run the repository graph update, and commit only files owned by this step. Preserve pre-existing unrelated working-tree changes.

## Verification

On the synthetic database, verify the upgrade, default, foreign key, supported-code constraint, and down migration. Confirm `taskgen_svc`'s existing table-level `INSERT`/`UPDATE` privileges continue to cover the added column. No service behavior or other repo is changed here.
