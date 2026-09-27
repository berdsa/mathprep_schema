# Independent student tenant kind

Migration `000099_student_tenant_kind` adds `student` as a valid
`mathprep.access_tenants.kind`. It gives a student account an accurately named,
isolated authorization scope without creating a family, parent, guardian, or
school relationship.

The migration does not create learner profiles, curriculum `students` rows,
grade placement, guardian links, consent, or learning access. Services must
continue to check the relevant profile and consent records before exposing
learning data. A student account may authenticate while its learning profile
is incomplete.

The down migration refuses to run while a `student` tenant exists. Migrate
student accounts deliberately before rolling back this schema version.
