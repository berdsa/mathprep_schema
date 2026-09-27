-- The platform API provisions child identities in the existing canonical
-- USERS/STUDENTS tables. Keep that compatibility boundary column-scoped.
CREATE ROLE platform_api_svc
    NOLOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT;

GRANT USAGE ON SCHEMA public TO platform_api_svc;

GRANT INSERT (user_id, user_type)
    ON public.users TO platform_api_svc;

GRANT SELECT (user_id, grade), INSERT (user_id, grade), UPDATE (grade)
    ON public.students TO platform_api_svc;
