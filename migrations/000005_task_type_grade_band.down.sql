ALTER TABLE task_type
    DROP CONSTRAINT task_type_grade_band_fk;

ALTER TABLE task_type
    ALTER COLUMN grade TYPE INTEGER USING grade::INTEGER;
