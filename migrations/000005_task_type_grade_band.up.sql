ALTER TABLE task_type
    ALTER COLUMN grade TYPE TEXT USING grade::TEXT;

ALTER TABLE task_type
    ADD CONSTRAINT task_type_grade_band_fk
    FOREIGN KEY (grade) REFERENCES grade_band(code);
