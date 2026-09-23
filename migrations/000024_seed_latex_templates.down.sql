BEGIN;
DELETE FROM task_type_template WHERE type_id = 'G5-FRA-003' AND locale = 'ru-KZ' AND render_target = 'latex' AND spec_version = '1.0.0-draft';
COMMIT;
