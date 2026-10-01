-- Reconcile the actual engine-query manifest with service privileges.
-- This migration is additive to object layout but contracts broad historical
-- table grants that allowed taskgen/grader to mutate billing and unrelated
-- engine objects. Run only after services with qualified SQL are deployed.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='taskgen_svc')
       OR NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='grader_svc')
       OR NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cas_svc') THEN
        RAISE EXCEPTION '000131 requires taskgen_svc, grader_svc, and cas_svc roles';
    END IF;
    IF to_regclass('public.generation_request') IS NULL
       OR to_regclass('public.task_set') IS NULL
       OR to_regclass('public.task_instance') IS NULL
       OR to_regclass('public.task_type') IS NULL
       OR to_regclass('public.task_type_template') IS NULL
       OR to_regclass('public.submission') IS NULL
       OR to_regclass('public.mastery_topic') IS NULL
       OR to_regclass('public.cas_evaluation_request') IS NULL
       OR to_regclass('public.cas_submission') IS NULL
       OR to_regclass('public.event_log') IS NULL THEN
        RAISE EXCEPTION '000131 requires the reviewed public engine relations';
    END IF;
END $$;

REVOKE ALL ON TABLE
    public.billing_order,
    public.billing_order_child,
    public.payment_attempt,
    public.verified_provider_event,
    public.child_entitlement_period
    FROM taskgen_svc, grader_svc;

REVOKE ALL ON TABLE
    public.generation_request,
    public.task_set,
    public.task_instance,
    public.task_type,
    public.task_type_template,
    public.students,
    public.submission,
    public.mastery_topic,
    public.cas_evaluation_request,
    public.cas_submission,
    public.event_log
    FROM taskgen_svc, grader_svc;

GRANT SELECT, INSERT, UPDATE ON public.generation_request TO taskgen_svc;
GRANT SELECT, INSERT ON public.task_set TO taskgen_svc;
GRANT SELECT, INSERT ON public.task_instance TO taskgen_svc;
GRANT SELECT, INSERT, UPDATE ON public.task_type TO taskgen_svc;
GRANT SELECT ON public.task_type_template, public.students TO taskgen_svc;
GRANT INSERT ON public.event_log TO taskgen_svc;

GRANT SELECT ON public.task_type, public.task_instance, public.task_set TO grader_svc;
GRANT SELECT, INSERT ON public.submission TO grader_svc;
GRANT SELECT, INSERT, UPDATE ON public.mastery_topic TO grader_svc;
GRANT SELECT, INSERT ON public.cas_evaluation_request, public.cas_submission TO grader_svc;
GRANT INSERT ON public.event_log TO grader_svc;

-- CAS has only its queue lifecycle and append-only event access. Existing
-- column-level UPDATE grants are retained; the table-level SELECT/INSERT grant
-- is needed for the worker's claim/update RETURNING statements.
GRANT SELECT, INSERT ON public.cas_evaluation_request TO cas_svc;
GRANT INSERT ON public.event_log TO cas_svc;
