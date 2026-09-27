-- Allow a learner to hold an independent account scope without representing
-- that account as a family or implying a guardian relationship.
ALTER TABLE mathprep.access_tenants
    DROP CONSTRAINT access_tenants_kind_check;

ALTER TABLE mathprep.access_tenants
    ADD CONSTRAINT access_tenants_kind_check
    CHECK (kind IN ('family', 'organization', 'student'));
