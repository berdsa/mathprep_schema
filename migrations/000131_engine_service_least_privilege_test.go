package migrations

import (
	"os"
	"strings"
	"testing"
)

func TestEngineServiceLeastPrivilegeMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000131_engine_service_least_privilege.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000131_engine_service_least_privilege.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")
	for _, required := range []string{
		"000131 requires taskgen_svc, grader_svc, and cas_svc roles",
		"000131 requires the reviewed public engine relations",
		"REVOKE ALL ON TABLE public.billing_order, public.billing_order_child, public.payment_attempt, public.verified_provider_event, public.child_entitlement_period FROM taskgen_svc, grader_svc",
		"GRANT SELECT, INSERT, UPDATE ON public.generation_request TO taskgen_svc",
		"GRANT SELECT, INSERT ON public.task_set TO taskgen_svc",
		"GRANT SELECT, INSERT ON public.task_instance TO taskgen_svc",
		"GRANT SELECT, INSERT, UPDATE ON public.task_type TO taskgen_svc",
		"GRANT SELECT ON public.task_type_template, public.students TO taskgen_svc",
		"GRANT INSERT ON public.event_log TO taskgen_svc",
		"GRANT SELECT ON public.task_type, public.task_instance, public.task_set TO grader_svc",
		"GRANT SELECT, INSERT ON public.submission TO grader_svc",
		"GRANT SELECT, INSERT, UPDATE ON public.mastery_topic TO grader_svc",
		"GRANT SELECT, INSERT ON public.cas_evaluation_request, public.cas_submission TO grader_svc",
		"GRANT INSERT ON public.event_log TO grader_svc",
		"GRANT SELECT, INSERT ON public.cas_evaluation_request TO cas_svc",
	} {
		if !strings.Contains(up, required) {
			t.Errorf("up migration is missing contract %q", required)
		}
	}
	if strings.Contains(up, "GRANT ALL") || strings.Contains(up, " TO PUBLIC") {
		t.Error("up migration must not widen privileges")
	}
	if !strings.Contains(down, "REVOKE ALL ON TABLE") || !strings.Contains(down, "public.billing_order") {
		t.Error("down migration must restore a bounded service rollback path")
	}
}
