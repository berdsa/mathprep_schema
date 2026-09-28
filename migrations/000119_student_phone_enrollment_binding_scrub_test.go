package migrations

import (
    "os"
    "strings"
    "testing"
)

func TestStudentPhoneEnrollmentBindingScrubMigrationContract(t *testing.T) {
    upBytes, err := os.ReadFile("000119_student_phone_enrollment_binding_scrub.up.sql")
    if err != nil { t.Fatal(err) }
    downBytes, err := os.ReadFile("000119_student_phone_enrollment_binding_scrub.down.sql")
    if err != nil { t.Fatal(err) }
    up, down := string(upBytes), string(downBytes)
    if !strings.Contains(up, "ALTER COLUMN device_binding DROP NOT NULL") { t.Fatal("up migration must allow terminal binding scrub") }
    if !strings.Contains(down, "WHERE device_binding IS NULL") || !strings.Contains(down, "ALTER COLUMN device_binding SET NOT NULL") { t.Fatal("down migration must guard restoration against scrubbed rows") }
}
