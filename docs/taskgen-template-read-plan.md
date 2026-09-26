# Taskgen template read — 2026-09-26

Ken authorized completing the local platform. A real taskgen service running as
`taskgen_svc` cannot generate a template-backed item: SELECT on
`task_type_template` is absent. This is existing generation infrastructure,
not a new task type or a Confirmation Gate.

Add migration 000097 granting SELECT only on the localized template table.
Verify forbidden template updates remain denied, event_log remains insert-only,
and a real generation request completes. Test fresh schema bootstrap separately.
Record the evidence and commit this schema step independently of math_gen.
