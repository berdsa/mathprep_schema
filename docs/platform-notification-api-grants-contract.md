# Platform API notification privileges

Migration `000124_platform_notification_api_grants` supplies the least-column
database privileges used by the Platform API notification producer and
authenticated inbox list/read handlers. It depends on the inbox/session/outbox
objects established by migrations `000102` and `000123`, and on the existing
`platform_api_svc` group role. It fails closed if those dependencies or the
referenced query columns are missing, or if the 000102 outbox identity INSERT
grants are absent.

## Granted access

The API may select the inbox identity, event kind, typed reference, class,
timestamps, recipient, and tenant fields required to list notifications and
evaluate current authorization. It may insert only the seven inbox columns
written by the placement and assessment producers, update only `read_at`, and
select `id` (included in the inbox SELECT list) for the producer's
`INSERT ... RETURNING id` statement.

Recipient resolution and inbox authorization receive column-only SELECT on:

| Relation | Columns |
|---|---|
| `platform_learning_sessions` | `id, test_id, child_id, mode, status, finished_at` |
| `platform_tests` | `id, class_id` |
| `platform_classes` | `id, school_id` |
| `platform_schools` | `id, tenant_id` |
| `access_tenants` | `id, status` |
| `platform_children` | `id, tenant_id, status, principal_id, learner_id` |
| `platform_placements` | `child_id, class_id, status` |
| `access_memberships` | `tenant_id, principal_id, status, role` |
| `access_principals` | `id, status` |
| `platform_teacher_classes` | `class_id, principal_id` |
| `platform_join_requests` | `id, class_id, child_id` |
| `access_guardian_relationships` | `learner_id, tenant_id, guardian_principal_id, state` |

No role-level `SELECT`, `INSERT`, or `UPDATE` is granted on these relations;
no notification deletes or writes to recipient-resolution tables are granted.
Outbox INSERT remains governed only by the existing 000102 column grant on
`notification_id, recipient_principal_id, event_kind`.

## Runtime role provisioning

Deployment-specific Platform API logins must be members of `platform_api_svc`
and inherit its privileges. The schema migration grants to the canonical group
role; it does not alter login roles, membership, credentials, or the local
development role. Local integration tests that connect as a broader role do
not prove that production group-role queries are authorized. Validate the
effective privileges through `SET ROLE platform_api_svc` or a dedicated login
after applying the migration.

The down migration revokes precisely the grants introduced here. It leaves
000102 outbox grants and existing role memberships unchanged.
