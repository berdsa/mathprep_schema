package validation

import (
	"testing"

	core "github.com/berdsa/mathprep_schema"
)

func TestValidateExactIntCorrect(t *testing.T) {
	result := ValidateExactInt("  +00042  ", "42")

	if result.Verdict != core.VerdictCorrect || result.ReasonCode != core.ReasonOK {
		t.Fatalf("got verdict=%q reason=%q, want CORRECT/OK", result.Verdict, result.ReasonCode)
	}
	if result.Normalized != "42" || result.Stage != StageVerdict {
		t.Fatalf("got normalized=%q stage=%q, want 42/verdict", result.Normalized, result.Stage)
	}
}

func TestValidateExactIntIncorrect(t *testing.T) {
	result := ValidateExactInt("41", "42")

	if result.Verdict != core.VerdictIncorrect || result.ReasonCode != core.ReasonValueMismatch {
		t.Fatalf("got verdict=%q reason=%q, want INCORRECT/VALUE_MISMATCH", result.Verdict, result.ReasonCode)
	}
}

func TestValidateExactIntUnparseable(t *testing.T) {
	result := ValidateExactInt("4.2", "42")

	if result.Verdict != core.VerdictUnparseable || result.ReasonCode != core.ReasonWrongFormat {
		t.Fatalf("got verdict=%q reason=%q, want UNPARSEABLE/WRONG_FORMAT", result.Verdict, result.ReasonCode)
	}
	if result.Stage != StageParse {
		t.Fatalf("got stage=%q, want parse", result.Stage)
	}
}

func TestValidateExactIntBoundary(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		reason core.ReasonCode
	}{
		{name: "five digits accepted", input: "99999", reason: core.ReasonOK},
		{name: "six digits fail grammar", input: "100000", reason: core.ReasonWrongFormat},
		{name: "more than six characters too long", input: "1000000", reason: core.ReasonInputTooLong},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, reason, _ := ParseExactInt(test.input)
			if reason != test.reason {
				t.Fatalf("got reason=%q, want %q", reason, test.reason)
			}
		})
	}
}
