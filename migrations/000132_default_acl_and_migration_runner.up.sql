-- Reconcile only the catalog-proven broad future grants. Existing explicit
-- service grants remain the runtime contract. The runner state relation makes
-- failed/nontransactional handling visible without rewriting historical ledgers.
CREATE TABLE IF NOT EXISTS mathprep.migration_runner_state (
    version varchar(64) PRIMARY KEY,
    checksum char(64) NOT NULL,
    state text NOT NULL CHECK (state IN ('running', 'failed', 'applied')),
    updated_at timestamptz NOT NULL DEFAULT now(),
    error_summary text
);

ALTER DEFAULT PRIVILEGES FOR ROLE mathprep IN SCHEMA public
    REVOKE ALL ON TABLES FROM taskgen_svc, grader_svc;
ALTER DEFAULT PRIVILEGES FOR ROLE mathprep IN SCHEMA public
    REVOKE ALL ON SEQUENCES FROM taskgen_svc, grader_svc;
ALTER DEFAULT PRIVILEGES FOR ROLE mathprep_owner IN SCHEMA mathprep
    REVOKE ALL ON TABLES FROM mathprep_app;

-- Restore reviewed current-object grants after the table-wide cleanup.
GRANT SELECT, INSERT, UPDATE ON public.generation_request TO taskgen_svc;
GRANT SELECT, INSERT ON public.task_set, public.task_instance TO taskgen_svc;
GRANT SELECT, INSERT, UPDATE ON public.task_type TO taskgen_svc;
GRANT SELECT ON public.task_type_template, public.students TO taskgen_svc;
GRANT INSERT ON public.event_log TO taskgen_svc;

GRANT SELECT ON public.task_type, public.task_instance, public.task_set TO grader_svc;
GRANT SELECT, INSERT ON public.submission, public.cas_evaluation_request, public.cas_submission TO grader_svc;
GRANT SELECT, INSERT, UPDATE ON public.mastery_topic TO grader_svc;
GRANT INSERT ON public.event_log TO grader_svc;
