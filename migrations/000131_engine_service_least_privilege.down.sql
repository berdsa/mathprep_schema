-- Roll back only this grant contraction. Recreate the superseded broad
-- taskgen/grader billing grants exactly enough for a service-image rollback.
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

GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.generation_request, public.task_set, public.task_instance
    TO taskgen_svc;
GRANT SELECT, INSERT, UPDATE ON public.task_type TO taskgen_svc;
GRANT SELECT ON public.mastery_topic, public.students, public.task_type_template TO taskgen_svc;
GRANT INSERT ON public.event_log TO taskgen_svc;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.submission, public.mastery_topic
    TO grader_svc;
GRANT SELECT ON public.task_instance, public.task_set, public.task_type TO grader_svc;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cas_submission TO grader_svc;
GRANT SELECT, INSERT ON public.cas_evaluation_request TO grader_svc;
GRANT INSERT ON public.event_log TO grader_svc;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.billing_order, public.billing_order_child, public.payment_attempt,
       public.verified_provider_event, public.child_entitlement_period
    TO taskgen_svc, grader_svc;
