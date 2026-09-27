-- Permit a signed-in principal to change only their own display name and
-- interface locale through Platform API. Email, password, role and tenant
-- fields remain outside this grant.
GRANT UPDATE (name, locale)
    ON mathprep.platform_accounts TO platform_api_svc;
