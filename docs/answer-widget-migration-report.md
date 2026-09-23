# Answer-widget migration report

Applied migrations `000011` through `000016` to the local 658-type catalog after the existing template migration. The resulting checks were:

- `task_type` rows: 658
- `answer_widget IS NULL`: 0
- BOOL types: 106
- BOOL types with missing/empty `widget_config.choices`: 0
- Active render targets: `plaintext`, `unicode-math`, `latex`
- Template rows: 5, all existing rows retained as `plaintext`

The widget distribution is: NUMERIC 381 (`EXACT-INT` + `TOL`), FRACTION 66, CHOICE 106, TUPLE_N 30, SET_LIST 13, MATRIX_GRID 2, and STRUCTURED_CANON 60. The eight-value `answer_widget` dictionary and the mechanical validation-method mapping are exported from `pkg/core` and owned by the schema migrations.

BOOL choices use the accepted tokens from the shared validator whitelist, including its quadrant-label branch (`i`, `ii`, `iii`, `iv`, `ox`, `oy`, `o`); no new answer vocabulary was invented.
