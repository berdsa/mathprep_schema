# 2026-10-01 catalog-derived baseline

Identity: `catalog-baseline-2026-10-01`. This is a reviewed reconstruction for
clean local installations, not recovered historical intent and not an applied
historical migration. It was mechanically derived from the data-free live
catalog extraction at `docs/db/LIVE-CATALOG-DDL-2026-10-01.sql` by removing
only pg_dump's random `\\restrict`/`\\unrestrict` control lines. The resulting
`catalog.sql` SHA-256 is
`447350a312f1785acf5e64126788d4884f24ba4b53f0b36f29a86db7cc74adb7`.

Fresh flow: create an empty database from `template0`, remove its default
`public` schema, run `roles.sql` as the controlled bootstrap administrator,
run `catalog.sql`, seed non-personal engine dictionaries with
`engine-dictionaries.sql` (values copied from migrations `000002`, `000009`,
`000014`, and `000094` only where their object creation is already embodied by
the catalog), then use `scripts/dbmigrate.sh apply` with
`baseline-marker.sql`.
The bootstrap marker is `9000_catalog_baseline_20261001`; it is new
bookkeeping and is never a claim that legacy migrations ran.

Existing-database flow never executes `catalog.sql`. It verifies the recorded
catalog checksum/fingerprint and writes only the same adoption marker through
the migration runner. Later additive migrations remain independently
checksummed and ledgered. This baseline contains no table data; do not use it
to copy students, users, answers, sessions, operational rows, secrets, or old
ledger history.
