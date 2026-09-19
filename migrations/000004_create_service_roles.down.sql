REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM taskgen_svc, grader_svc;
REVOKE USAGE ON SCHEMA public FROM taskgen_svc, grader_svc;
DROP ROLE grader_svc;
DROP ROLE taskgen_svc;
