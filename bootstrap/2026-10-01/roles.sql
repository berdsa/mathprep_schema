-- Catalog-baseline prerequisites only.  Passwords and LOGIN attributes are
-- deliberately not source-controlled; local identities are provisioned by
-- the remediation operator after this prerequisite pass.
DO $$
DECLARE role_name text;
BEGIN
  FOREACH role_name IN ARRAY ARRAY[
    'taskgen_svc', 'grader_svc', 'cas_svc', 'platform_api_svc',
    'mathprep_owner', 'mathprep_migrator', 'mathprep_app',
    'mathprep_platform_local', 'mathprep_notifications_svc',
    'platform_auth_retention_svc'
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS', role_name);
    END IF;
  END LOOP;
END $$;

GRANT platform_api_svc TO mathprep_platform_local;
GRANT mathprep_owner TO mathprep_migrator;
