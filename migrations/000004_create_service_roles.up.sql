CREATE ROLE taskgen_svc
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT;

CREATE ROLE grader_svc
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT;

REVOKE ALL ON event_log FROM taskgen_svc, grader_svc;
REVOKE ALL ON generation_request, task_set, task_instance, task_type, mastery_topic
    FROM taskgen_svc;
REVOKE ALL ON submission, mastery_topic, task_instance
    FROM grader_svc;

GRANT USAGE ON SCHEMA public TO taskgen_svc, grader_svc;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON generation_request, task_set, task_instance
    TO taskgen_svc;
GRANT SELECT ON task_type, mastery_topic TO taskgen_svc;
GRANT INSERT ON event_log TO taskgen_svc;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON submission, mastery_topic
    TO grader_svc;
GRANT SELECT ON task_instance TO grader_svc;
GRANT INSERT ON event_log TO grader_svc;
