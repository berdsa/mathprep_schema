package core

import (
	_ "embed"
	"encoding/json"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"testing"
)

// This snapshot is the reviewed contract for the currently populated catalog.
// The test queries the live task_type table, so a changed row fails even when
// the dictionary constants and migration-completeness checks still pass.
//
//go:embed testdata/widget_config_expected.json
var widgetConfigExpected []byte

type widgetConfigSnapshot struct {
	Choices []string                      `json:"choices"`
	Tuple   map[string]tupleWidgetConfig  `json:"tuple"`
	Matrix  map[string]matrixWidgetConfig `json:"matrix"`
	Canon   map[string]string             `json:"canon"`
}

type tupleWidgetConfig struct {
	Fields     []widgetField `json:"fields"`
	FieldCount int           `json:"field_count"`
}

type widgetField struct {
	Key   string `json:"key"`
	Label string `json:"label"`
}

type matrixWidgetConfig struct {
	Rows      int    `json:"rows"`
	Columns   int    `json:"columns"`
	CellLabel string `json:"cell_label"`
}

type taskTypeWidgetRow struct {
	ID     string
	Method string
	Widget string
	Config json.RawMessage
}

func TestPopulatedWidgetConfigContracts(t *testing.T) {
	var expected widgetConfigSnapshot
	if err := json.Unmarshal(widgetConfigExpected, &expected); err != nil {
		t.Fatal(err)
	}
	rows := loadTaskTypeWidgetRows(t)
	seen := map[string]bool{}
	for _, row := range rows {
		seen[row.ID] = true
		var got map[string]any
		if err := json.Unmarshal(row.Config, &got); err != nil {
			t.Fatalf("%s: malformed widget_config: %v", row.ID, err)
		}
		switch row.Widget {
		case string(AnswerWidgetChoice):
			var config struct {
				Choices []string `json:"choices"`
			}
			decodeConfig(t, row, &config)
			if !equalStrings(config.Choices, expected.Choices) {
				t.Errorf("%s: choices changed; got %v, want exact validator whitelist %v", row.ID, config.Choices, expected.Choices)
			}
		case string(AnswerWidgetTupleN):
			want, ok := expected.Tuple[row.ID]
			if !ok {
				t.Fatalf("%s: no tuple contract snapshot", row.ID)
			}
			var config tupleWidgetConfig
			decodeConfig(t, row, &config)
			if config.FieldCount != len(config.Fields) {
				t.Errorf("%s: field_count=%d but has %d fields", row.ID, config.FieldCount, len(config.Fields))
			}
			if config.FieldCount != want.FieldCount || !equalFields(config.Fields, want.Fields) {
				t.Errorf("%s: tuple shape changed; got %+v, want %+v", row.ID, config, want)
			}
		case string(AnswerWidgetMatrixGrid):
			want, ok := expected.Matrix[row.ID]
			if !ok {
				t.Fatalf("%s: no matrix contract snapshot", row.ID)
			}
			var config matrixWidgetConfig
			decodeConfig(t, row, &config)
			if config.Rows <= 0 || config.Columns <= 0 {
				t.Errorf("%s: invalid matrix dimensions %+v", row.ID, config)
			}
			if config != want {
				t.Errorf("%s: matrix shape changed; got %+v, want %+v", row.ID, config, want)
			}
		case string(AnswerWidgetStructuredCanon):
			want, ok := expected.Canon[row.ID]
			if !ok {
				t.Fatalf("%s: no CANON contract snapshot", row.ID)
			}
			var config struct {
				Template struct {
					Template string `json:"template"`
				} `json:"template"`
			}
			decodeConfig(t, row, &config)
			gotTemplate := config.Template.Template
			if gotTemplate != want || !wellFormedCanonTemplate(gotTemplate) {
				t.Errorf("%s: CANON template changed or malformed; got %q, want %q", row.ID, gotTemplate, want)
			}
			if row.Method != string(ValidationMethodCanon) {
				t.Errorf("%s: STRUCTURED_CANON paired with %s, want CANON", row.ID, row.Method)
			}
		}
	}
	for id := range expected.Tuple {
		if !seen[id] {
			t.Errorf("tuple snapshot %s is absent from task_type", id)
		}
	}
	for id := range expected.Matrix {
		if !seen[id] {
			t.Errorf("matrix snapshot %s is absent from task_type", id)
		}
	}
	for id := range expected.Canon {
		if !seen[id] {
			t.Errorf("canon snapshot %s is absent from task_type", id)
		}
	}
}

func loadTaskTypeWidgetRows(t *testing.T) []taskTypeWidgetRow {
	t.Helper()
	args := []string{"-X", "-A", "-t", "-F", "\t", "-c", "SELECT type_id, validation_method, answer_widget, widget_config::text FROM task_type WHERE answer_widget IN ('CHOICE','TUPLE_N','MATRIX_GRID','STRUCTURED_CANON') ORDER BY type_id;"}
	command := "psql"
	if _, err := exec.LookPath(command); err != nil {
		command = "docker"
		args = append([]string{"exec", "-i", "postgres", "psql", "-U", "mathprep", "-d", "mathprep"}, args...)
	}
	cmd := exec.Command(command, args...)
	env := os.Environ()
	for _, pair := range []string{"MATHPREP_TEST_HOST=PGHOST", "MATHPREP_TEST_PORT=PGPORT", "MATHPREP_TEST_USER=PGUSER", "MATHPREP_TEST_PASSWORD=PGPASSWORD", "MATHPREP_TEST_DATABASE=PGDATABASE"} {
		parts := strings.SplitN(pair, "=", 2)
		if value := os.Getenv(parts[0]); value != "" {
			env = append(env, parts[1]+"="+value)
		}
	}
	cmd.Env = env
	out, err := cmd.Output()
	if err != nil {
		if os.Getenv("MATHPREP_TEST_DATABASE") == "" {
			t.Skip("no configured PostgreSQL catalog and the local postgres container is unavailable")
		}
		t.Fatalf("query task_type widget data: %v", err)
	}
	var rows []taskTypeWidgetRow
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		parts := strings.SplitN(line, "\t", 4)
		if len(parts) != 4 {
			t.Fatalf("malformed psql row %q", line)
		}
		rows = append(rows, taskTypeWidgetRow{ID: parts[0], Method: parts[1], Widget: parts[2], Config: json.RawMessage(parts[3])})
	}
	return rows
}

func decodeConfig(t *testing.T, row taskTypeWidgetRow, dst any) {
	t.Helper()
	if err := json.Unmarshal(row.Config, dst); err != nil {
		t.Fatalf("%s: decode widget_config: %v", row.ID, err)
	}
}

func equalStrings(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func equalFields(a, b []widgetField) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

var canonPlaceholder = regexp.MustCompile(`\{[A-Za-z][A-Za-z0-9_]*\}`)

func wellFormedCanonTemplate(template string) bool {
	if strings.TrimSpace(template) == "" || strings.Contains(template, "{}") {
		return false
	}
	depth := 0
	for _, r := range template {
		switch r {
		case '{':
			depth++
		case '}':
			depth--
			if depth < 0 {
				return false
			}
		}
	}
	return depth == 0 && (canonPlaceholder.MatchString(template) || !strings.ContainsAny(template, "{}"))
}
