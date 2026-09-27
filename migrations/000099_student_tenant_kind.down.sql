DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.access_tenants WHERE kind = 'student') THEN
        RAISE EXCEPTION 'cannot remove student tenant kind while student tenants exist';
    END IF;
END $$;

ALTER TABLE mathprep.access_tenants
    DROP CONSTRAINT access_tenants_kind_check;

ALTER TABLE mathprep.access_tenants
    ADD CONSTRAINT access_tenants_kind_check
    CHECK (kind IN ('family', 'organization'));
