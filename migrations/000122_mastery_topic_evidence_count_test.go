package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestMasteryTopicEvidenceCountMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000122_mastery_topic_evidence_count.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000122_mastery_topic_evidence_count.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")

	for _, required := range []string{
		"LOCK TABLE public.mastery_topic IN ACCESS EXCLUSIVE MODE",
		"LOCK TABLE public.event_log IN SHARE MODE",
		"ADD COLUMN evidence_count BIGINT",
		"COUNT(*)::bigint AS evidence_count",
		"ALTER COLUMN evidence_count SET NOT NULL",
		"CHECK (evidence_count >= 0)",
		"event_type = 'MASTERY_UPDATED'",
		"current mastery row has no source event",
		"MASTERY_UPDATED event has no current mastery row",
		"last source-event timestamp disagrees with mastery.updated_at",
		"ORDER BY e.occurred_at, e.event_id",
		"source-event EMA replay disagrees with mastery.ema_score",
		"NEW.evidence_count := OLD.evidence_count + 1",
		"NEW.evidence_count := 1",
		"GRANT SELECT (evidence_count) ON public.mastery_topic TO platform_api_svc",
		"TO mathprep_platform_local",
	} {
		if !strings.Contains(up, required) {
			t.Errorf("up migration is missing contract %q", required)
		}
	}
	if strings.Contains(up, "GRANT SELECT ON public.event_log") || strings.Contains(up, "ON public.event_log TO platform_api_svc") {
		t.Error("migration must not grant Platform API access to EVENT_LOG")
	}
	if strings.Contains(up, "GRANT INSERT") || strings.Contains(up, "GRANT UPDATE") {
		t.Error("grader count maintenance is trigger-owned; migration must not broaden grader grants")
	}
	if strings.Contains(up, "DEFAULT 0") {
		t.Error("evidence_count must not silently start new mastery rows at zero")
	}
	for _, required := range []string{
		"REVOKE SELECT (evidence_count) ON public.mastery_topic FROM platform_api_svc",
		"FROM mathprep_platform_local",
		"DROP TRIGGER mastery_topic_evidence_count_write ON public.mastery_topic",
		"DROP FUNCTION public.set_mastery_topic_evidence_count()",
		"DROP COLUMN evidence_count",
	} {
		if !strings.Contains(down, required) {
			t.Errorf("down migration is missing rollback %q", required)
		}
	}

	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "5c9a30d853484bab956cff9dee124cf4df099df717a59fb3dec97e582663c8f8" {
		t.Errorf("up checksum changed: %s", upSum)
	}
	if downSum != "95a787dfc64aa238fb3d5808d622435d9eaa2005a852c18b621a973a8d9b6772" {
		t.Errorf("down checksum changed: %s", downSum)
	}
}
