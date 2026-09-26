INSERT INTO locale (code) VALUES
    ('kk-KZ'),
    ('en-US');

ALTER TABLE generation_request
    ADD COLUMN locale TEXT NOT NULL DEFAULT 'ru-KZ'
        REFERENCES locale(code)
        CHECK (locale IN ('ru-KZ', 'kk-KZ', 'en-US'));

COMMENT ON COLUMN generation_request.locale IS
    'Persisted request locale preference; generated task locale is frozen on task_instance.locale.';
