ALTER TABLE generation_request
    DROP COLUMN locale;

DELETE FROM locale
WHERE code IN ('kk-KZ', 'en-US');
