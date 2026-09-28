# Student-owned private practice profile contract

An independently registered student may create one private self-owned practice profile in the student's own active `student` tenant. The profile is optional and never converts the student into a family child. Its opaque `profile_id` is the learner-facing ID used by Platform API routes and learning sessions; its engine student ID is a separate `public.users`/`public.students` identity created atomically with the profile.

## Scope and safeguards

- Creation and learning are development-only. The service must check `APP_ENV=development` before writes and again in `CanAccessChild`; production fails closed.
- The student must hold the exact active principal, tenant, membership, and `student` role. Only that owner may list, access, practice, answer, print, or inspect mastery/history for the profile.
- The acknowledgement is `student-self-preview-v1`, a notice that this is a local synthetic-data preview. It is not consent, age verification, a verified identity, guardianship, or authority to collect real children's data.
- Creation creates no legacy `parents`/`learners` row, family tenant, guardian relationship, `access_consents` row, or school placement. The profile is not visible to family, teacher, school, or regional queries.
- Existing family-child access remains governed by its live guardian relationship, granted learning consent, and (for independent student accounts) the separate two-party profile link. Self-owned access cannot preserve a revoked family grant.
- One row per student principal/tenant is allowed. The platform engine user and profile are inserted in one transaction; idempotent retrieval returns the existing profile without duplicating engine identities.
- Learning sessions have exactly one owner: a legacy family child or a self-profile. Existing family `child_id` FKs and session access checks remain intact.

## API and UI

`POST /api/platform/me/self-profile` accepts only `{name, grade, locale, preview_notice_acknowledged, preview_notice_version}`. Strict validation rejects missing, stale, or false acknowledgement. `GET /api/platform/me/self-profile` returns the current owned profile or an empty/not-created status. The response uses the profile ID as `id`, includes `self_owned: true`, and does not return a guardian/consent state. The frontend presents local practice as a primary option and family linking as optional; if both a self-profile and a linked family child exist, the user chooses the active profile explicitly.

## Validation

Required integration coverage: create once and retrieve idempotently; session generation, answer, grading, mastery, history, and print use the same profile ID; duplicate concurrent creates cannot duplicate engine users; transaction failures leave no partial profile; no family/guardian/consent rows are created; owner A cannot access owner B; parent/teacher/school queries cannot expose the profile; production mode denies creation and access; family access after consent withdrawal remains denied; revoking a family link does not affect a separate self-profile.

The base DDL for pre-existing platform identity and learning tables remains outside this schema repo. Migration `000117` therefore requires catalog and migration-ledger verification against the existing `mathprep` DB; it does not claim fresh-database reproducibility until those base table definitions are reconciled into canonical schema history.
