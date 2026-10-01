-- Reversible only for the new runner-state artifact. Do not reintroduce broad
-- default grants during rollback; explicit object grants remain intact.
DROP TABLE IF EXISTS mathprep.migration_runner_state;
