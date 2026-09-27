DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM mathprep.phone_identity) THEN
        RAISE EXCEPTION 'cannot drop mathprep.phone_identity while identity history exists; export/archive the rows deliberately first';
    END IF;
END $$;

DROP TABLE mathprep.phone_identity;
