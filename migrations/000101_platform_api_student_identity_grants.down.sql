REVOKE SELECT (user_id, grade), INSERT (user_id, grade), UPDATE (grade)
    ON public.students FROM platform_api_svc;
REVOKE INSERT (user_id, user_type)
    ON public.users FROM platform_api_svc;
REVOKE USAGE ON SCHEMA public FROM platform_api_svc;
DROP ROLE platform_api_svc;
