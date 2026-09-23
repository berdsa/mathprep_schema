# Widget configuration and LaTeX metadata log

This log covers all 658 existing `task_type` rows after schema v0.3.9. Structured configurations were audited against the taskgen generator return shape and seeded by validation-method batch. LaTeX is additive: only `G5-FRA-003` received a companion row because it is the only existing grade-5+ fraction plaintext template in the current pilot set; arithmetic pilot rows were intentionally skipped, and types without a DB plaintext row remain deferred. No generator, validator, or existing plaintext row changed.

## Per-type status

| Type ID | Validation method | Answer widget | widget_config | LaTeX template status |
|---|---|---|---|---|
| `G10-ALG-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-005` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-007` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-008` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-ALG-010` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-CAL-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-FUN-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-FUN-002` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-FUN-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-002` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-005` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-006` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-008` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-PRO-009` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-STA-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G10-TRG-001` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-ALG-001` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-FUN-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-LOG-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-MAT-001` | `MATRIX` | `MATRIX_GRID` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-MAT-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-NUM-001` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-PRO-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-STA-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-STA-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-STA-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-STA-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-STA-005` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-STA-006` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-TRG-001` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G11-VEC-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-001` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-002` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-003` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-004` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-006` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-GEO-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-004` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-009` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-MEA-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-015` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-017` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-018` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-019` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-020` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-021` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-022` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-023` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-024` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-025` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-NUM-026` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-STA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-STA-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-STA-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G1-STA-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-013` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-017` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-018` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-019` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-020` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-021` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-022` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-023` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-024` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-025` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-026` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-027` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-028` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-029` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-030` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-GEO-031` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-004` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-011` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-012` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-014` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-015` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-017` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-018` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-MEA-019` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-014` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-017` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-018` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-019` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-020` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-021` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-022` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-023` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-024` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-025` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-026` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-027` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-028` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-029` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-030` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-031` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-032` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-033` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-034` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-035` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-036` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-037` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-038` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-039` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-040` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-041` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-042` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-043` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-044` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-045` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-046` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-047` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-048` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-049` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-050` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-051` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-052` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-053` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-054` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-055` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-056` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-057` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-058` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-059` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-060` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-061` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-NUM-062` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-STA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-STA-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-STA-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-STA-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G2-STA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-FRA-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: pilot plaintext is arithmetic/under grade 5 |
| `G3-FRA-009` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-FRA-010` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-FRA-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-FRA-012` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-FRA-013` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-FRA-014` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-002` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-005` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-GEO-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-011` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-017` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-MEA-018` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: pilot plaintext is arithmetic/under grade 5 |
| `G3-NUM-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: pilot plaintext is arithmetic/under grade 5 |
| `G3-NUM-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-011` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-017` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-018` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-019` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-020` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-021` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-022` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-023` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-024` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-025` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-026` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-027` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-028` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-029` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-030` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-031` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-032` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-033` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-034` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-035` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-036` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-037` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-038` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-039` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-040` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-041` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-042` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-043` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-044` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-045` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-046` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-NUM-047` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-STA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-STA-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-STA-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G3-STA-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-002` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-003` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-004` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-005` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-006` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-007` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-FRA-008` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-002` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-005` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-GEO-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-013` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-MEA-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-002` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-010` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-012` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-013` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-014` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-015` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-017` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-018` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-019` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-020` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-021` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-022` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-023` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-024` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-025` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-026` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-027` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-028` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-029` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-030` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-031` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-032` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-033` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-034` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-035` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-NUM-036` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G4-STA-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-008` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-009` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-010` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-011` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-012` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-013` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-014` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DEC-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-DIS-001` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-002` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-003` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | added: real fraction template |
| `G5-FRA-004` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-005` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-006` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-007` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-008` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-009` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-FRA-010` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-GEO-001` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-GEO-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-GEO-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-006` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-MEA-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-002` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-005` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-NUM-010` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G5-STA-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-003` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-005` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-009` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-ALG-010` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-005` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-006` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-DEC-007` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-002` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-004` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-006` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-007` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-009` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-010` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-011` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-012` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-013` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-FRA-015` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-001` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-008` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-010` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-011` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-013` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-014` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-GEO-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-001` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: pilot plaintext is arithmetic/under grade 5 |
| `G6-NUM-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-004` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-NUM-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G6-STA-001` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-001` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-002` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-004` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-005` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-008` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-009` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-010` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-011` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-012` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-013` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-014` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-015` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-016` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-017` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-018` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-019` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-020` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-021` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-022` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-023` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-024` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-025` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-ALG-026` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-DEC-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-DEC-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-DEC-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-DEC-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FRA-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FRA-002` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FRA-003` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FRA-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FRA-005` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-002` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-005` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-009` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-010` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-011` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-012` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-FUN-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-005` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-006` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-008` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-010` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-012` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-013` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-015` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-016` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-017` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-018` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-019` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-020` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-021` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-022` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-023` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-GEO-024` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-006` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-009` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-010` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G7-STA-011` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-003` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-004` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-005` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-006` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-008` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-010` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-011` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-012` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-013` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-015` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-016` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-017` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-018` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-019` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-021` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-022` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-ALG-023` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-FUN-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-FUN-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-FUN-003` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-FUN-004` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-FUN-005` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-FUN-006` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-005` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-006` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-007` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-008` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-009` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-010` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-011` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-012` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-013` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-014` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-015` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-017` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-018` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-019` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-020` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-021` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-022` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-GEO-023` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-001` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-005` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-006` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-007` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-NUM-008` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G8-TRG-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-ALG-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-DIS-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-FUN-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-FUN-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-FUN-003` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-FUN-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-FUN-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-005` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-007` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-008` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-009` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-GEO-010` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-PRO-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-STA-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-STA-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-TRG-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-VEC-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `G9-VEC-002` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-002` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-003` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-005` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-006` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-007` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-ALG-008` | `CANON` | `STRUCTURED_CANON` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-001` | `EXACT-RAT` | `FRACTION` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-004` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-006` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-007` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-008` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-009` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-010` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-011` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-012` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-013` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-014` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-015` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-016` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-017` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-018` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-019` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-020` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-021` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-022` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-023` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-024` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-025` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-CAL-026` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-002` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-003` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-004` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-006` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-007` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-DIS-008` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-FUN-001` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-FUN-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-001` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-002` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-003` | `MATRIX` | `MATRIX_GRID` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-004` | `TUPLE` | `TUPLE_N` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-005` | `EXACT-INT` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-006` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-MAT-007` | `SET` | `SET_LIST` | real structured config | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-NUM-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-PRO-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-PRO-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-PRO-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-PRO-004` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-001` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-002` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-003` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-004` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-005` | `BOOL` | `CHOICE` | choices whitelist seeded | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-006` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-007` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-008` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |
| `U-STA-009` | `TOL` | `NUMERIC` | default mapping; no extra config required | not added: no existing plaintext DB row yet; deferred with template backfill |

## Checks

- Total task types: **658**.
- Structured widget configs: **105/105** (30 `TUPLE_N`, 13 `SET_LIST`, 2 `MATRIX_GRID`, 60 `STRUCTURED_CANON`).
- BOOL choices: **106/106** have non-empty validator-derived `choices` lists.
- LaTeX companion rows added: **1** (`G5-FRA-003`).
- Existing generation, validation, plaintext templates, and tests were not modified.
