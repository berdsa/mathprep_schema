BEGIN;

-- Relabel the persisted implemented catalog rows to their Kazakhstan-grade IDs,
-- including already-issued instances that reference those rows.
CREATE TEMP TABLE task_type_relabel (
    old_id TEXT PRIMARY KEY,
    new_id TEXT NOT NULL UNIQUE
) ON COMMIT DROP;

INSERT INTO task_type_relabel (old_id, new_id) VALUES
    ('G1-NUM-001', 'G2-NUM-001'),
    ('G1-NUM-002', 'G1-NUM-002'),
    ('G1-NUM-007', 'G1-NUM-007'),
    ('G1-NUM-008', 'G2-MEA-008'),
    ('G1-NUM-006', 'G2-NUM-006'),
    ('G1-NUM-005', 'G2-NUM-005'),
    ('G1-NUM-004', 'G1-NUM-004'),
    ('G1-NUM-003', 'G1-NUM-003'),
    ('G1-NUM-009', 'G2-NUM-009'),
    ('G1-NUM-010', 'G2-GEO-010'),
    ('G10-LINALG-001', 'G11-ALG-001'),
    ('G10-LOG-001', 'G11-LOG-001'),
    ('G10-CAL-001', 'G10-CAL-001'),
    ('G10-MAT-001', 'G11-MAT-001'),
    ('G10-ALG-001', 'G9-ALG-001'),
    ('G10-CPLX-001', 'G11-NUM-001'),
    ('G10-EXP-001', 'G11-FUN-001'),
    ('G10-SEQ-001', 'G9-FUN-001'),
    ('G3-NUM-001', 'G4-NUM-001'),
    ('G10-SP-001', 'G11-PRO-001'),
    ('G3-NUM-003', 'G3-NUM-003'),
    ('G3-NUM-004', 'G4-NUM-004'),
    ('G10-VEC-001', 'G9-VEC-001'),
    ('G10-SEQ-002', 'G9-FUN-002'),
    ('G3-NUM-002', 'G3-NUM-002'),
    ('G10-TRG-001', 'G10-TRG-001'),
    ('G3-NUM-011', 'G3-NUM-011'),
    ('G3-NUM-006', 'G3-NUM-006'),
    ('G3-NUM-008', 'G3-FRA-008'),
    ('G3-NUM-009', 'G3-MEA-009'),
    ('G3-NUM-005', 'G4-NUM-005'),
    ('G3-NUM-007', 'G3-NUM-007'),
    ('G3-NUM-012', 'G4-NUM-012'),
    ('G3-NUM-010', 'G3-MEA-010'),
    ('G3-NUM-017', 'G3-NUM-017'),
    ('G3-NUM-015', 'G3-NUM-015'),
    ('G3-NUM-018', 'G3-NUM-018'),
    ('G3-NUM-020', 'G3-NUM-020'),
    ('G3-NUM-013', 'G3-NUM-013'),
    ('G3-NUM-016', 'G3-NUM-016'),
    ('G3-NUM-021', 'G3-NUM-021'),
    ('G3-NUM-019', 'G3-NUM-019'),
    ('G6-FRA-004', 'G6-FRA-004'),
    ('G6-FRA-003', 'G5-FRA-003'),
    ('G6-DEC-001', 'G5-DEC-001'),
    ('G6-GEO-001', 'G6-GEO-001'),
    ('G6-MD-001', 'G5-MEA-001'),
    ('G6-GEO-002', 'G8-GEO-002'),
    ('G6-MD-002', 'G4-MEA-002'),
    ('G6-GEO-003', 'G7-GEO-003'),
    ('G6-PCT-001', 'G6-DEC-001'),
    ('G6-PCT-002', 'G6-DEC-002'),
    ('G6-NS-001', 'G5-NUM-001'),
    ('G6-RP-001', 'G6-FRA-001'),
    ('G6-SP-001', 'G10-PRO-001'),
    ('G6-RAT-001', 'G6-NUM-001'),
    ('G6-NS-002', 'G6-NUM-002'),
    ('G7-EE-004', 'G8-ALG-004'),
    ('G7-F-002', 'G7-FUN-002'),
    ('G7-EE-006', 'G7-ALG-006'),
    ('G7-EE-001', 'G6-ALG-001'),
    ('G7-EE-005', 'G7-ALG-005'),
    ('G7-F-001', 'G8-FUN-001'),
    ('G7-EE-003', 'G8-ALG-003'),
    ('G7-EE-002', 'G7-ALG-002'),
    ('G7-SP-002', 'G10-PRO-002'),
    ('G7-GEO-004', 'G8-TRG-004'),
    ('G7-NS-002', 'G5-NUM-002'),
    ('G7-NS-001', 'G5-DIS-001'),
    ('G7-SP-001', 'G9-DIS-001'),
    ('G7-GEO-003', 'G6-GEO-003'),
    ('G7-GEO-002', 'G9-GEO-002'),
    ('G7-GEO-001', 'G8-GEO-001'),
    ('UNI-DM-002', 'U-DIS-002'),
    ('UNI-CAL-004', 'U-CAL-004'),
    ('UNI-CAL-007', 'U-CAL-007'),
    ('UNI-PROB-002', 'U-PRO-002'),
    ('UNI-CAL-006', 'U-CAL-006'),
    ('UNI-DM-001', 'U-DIS-001'),
    ('UNI-CA-001', 'U-ALG-001'),
    ('UNI-CAL-001', 'U-CAL-001'),
    ('G7-SP-003', 'G7-STA-003'),
    ('UNI-NUM-001', 'U-NUM-001'),
    ('UNI-LINALG-003', 'U-MAT-003'),
    ('UNI-LINALG-001', 'U-MAT-001'),
    ('UNI-LINALG-004', 'U-MAT-004'),
    ('UNI-PROB-001', 'U-PRO-001'),
    ('UNI-LINALG-002', 'U-MAT-002'),
    ('UNI-SEQ-001', 'U-FUN-001'),
    ('UNI-DM-003', 'U-DIS-003'),
    ('UNI-SEQ-002', 'U-FUN-002');

ALTER TABLE task_instance DROP CONSTRAINT task_instance_type_id_fkey;

UPDATE task_type
SET type_id = '__catalog_relabel__' || type_id
WHERE type_id IN (SELECT old_id FROM task_type_relabel);

UPDATE task_instance
SET type_id = '__catalog_relabel__' || type_id
WHERE type_id IN (SELECT old_id FROM task_type_relabel);

INSERT INTO task_type (
    type_id, domain, grade, spec_version, generation_mode, status,
    equivalence_policy, validation_method, locale
)
SELECT r.new_id,
       split_part(r.new_id, '-', 2),
       CASE WHEN split_part(r.new_id, '-', 1) = 'U'
            THEN 'UNIVERSITY'
            ELSE regexp_replace(split_part(r.new_id, '-', 1), '^G', '')
       END,
       t.spec_version, t.generation_mode, t.status, t.equivalence_policy,
       t.validation_method, t.locale
FROM task_type t
JOIN task_type_relabel r ON t.type_id = '__catalog_relabel__' || r.old_id;

UPDATE task_instance ti
SET type_id = r.new_id
FROM task_type_relabel r
WHERE ti.type_id = '__catalog_relabel__' || r.old_id;

DELETE FROM task_type
WHERE strpos(type_id, '__catalog_relabel__') = 1;

ALTER TABLE task_instance
    ADD CONSTRAINT task_instance_type_id_fkey
    FOREIGN KEY (type_id) REFERENCES task_type(type_id);

COMMIT;
