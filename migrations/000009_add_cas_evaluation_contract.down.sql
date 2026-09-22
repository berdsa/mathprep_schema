REVOKE ALL PRIVILEGES ON cas_evaluation_request, event_log,
    cas_operation_type, cas_evaluation_status, verdict, reason_code, event_type
    FROM cas_svc;
REVOKE USAGE ON SCHEMA public FROM cas_svc;
DROP ROLE cas_svc;

DROP INDEX cas_evaluation_request_session_created_at_idx;
DROP INDEX cas_evaluation_request_claim_idx;
DROP TABLE cas_evaluation_request;

ALTER TABLE event_log
    DROP CONSTRAINT event_log_event_type_fkey;

DROP TABLE event_type;
DROP TABLE cas_evaluation_status;
DROP TABLE cas_operation_type;
