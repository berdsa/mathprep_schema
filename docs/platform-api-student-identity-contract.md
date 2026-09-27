# Platform API compatibility grants for student identity

The platform API's parent-owned child provisioning path creates canonical
`public.users` and `public.students` rows. These are the same identity records
read by task generation and other existing MathPrep services; this migration
does not create duplicate student tables or transfer canonical table ownership.

Migration `000101_platform_api_student_identity_grants` adds a non-login group
role and the minimum column privileges required by the platform API:

- `users`: insert `user_id` and `user_type` only.
- `students`: insert `user_id` and `grade`, read those columns for provisioning
  verification, and update `grade` for the platform's authorized profile edit.

No table-wide `SELECT`, `UPDATE`, or `DELETE` privilege is granted. A deployment
must grant membership in `platform_api_svc` to its platform-api login role. The
canonical migration intentionally does not name a deployment-specific login;
the local Compose bootstrap assigns the group to `mathprep_platform_local`.

Rollback revokes the column grants and drops the group role. Remove memberships
from deployment login roles before applying the down migration. This migration
does not change user/student rows or grant any privilege to taskgen/grader.
