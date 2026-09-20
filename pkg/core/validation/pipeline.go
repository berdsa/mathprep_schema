// Package validation contains the shared answer-validation pipeline.
package validation

import (
	"regexp"
	"strconv"
	"strings"

	core "github.com/berdsa/mathprep_schema/pkg/core"
)

type Stage string

const (
	StageParse     Stage = "parse"
	StageNormalize Stage = "normalize"
	StageCompare   Stage = "compare"
	StageVerdict   Stage = "verdict"
)

type Result struct {
	Verdict       core.Verdict
	ReasonCode    core.ReasonCode
	Normalized    string
	Stage         Stage
	CorrectAnswer string
}

// Validate dispatches through the task type's declared validation method.
// New validators belong here so the submission handler remains generic.
func Validate(method core.ValidationMethod, raw, correctAnswer string) Result {
	switch method {
	case core.ValidationMethodExactInt:
		return ValidateExactInt(raw, correctAnswer)
	default:
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
}

// ParsedExactInt is the parse-stage representation of an EXACT-INT answer.
// Its digits have passed the input contract but have not been numerically
// normalized yet.
type ParsedExactInt struct {
	digits string
}

var exactIntInput = regexp.MustCompile(`^\s*\+?0*([0-9]{1,5})\s*$`)

func ParseExactInt(raw string) (ParsedExactInt, core.ReasonCode, Stage) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ParsedExactInt{}, core.ReasonEmptyInput, StageParse
	}
	if strings.ContainsAny(trimmed, ",.") {
		return ParsedExactInt{}, core.ReasonWrongFormat, StageParse
	}
	if len(trimmed) > 6 {
		return ParsedExactInt{}, core.ReasonInputTooLong, StageParse
	}

	match := exactIntInput.FindStringSubmatch(raw)
	if len(match) != 2 {
		return ParsedExactInt{}, core.ReasonWrongFormat, StageParse
	}
	return ParsedExactInt{digits: match[1]}, core.ReasonOK, StageParse
}

func NormalizeExactInt(parsed ParsedExactInt) (string, core.ReasonCode, Stage) {
	if parsed.digits == "" {
		return "", core.ReasonParseError, StageNormalize
	}

	value, err := strconv.ParseUint(parsed.digits, 10, 64)
	if err != nil {
		return "", core.ReasonParseError, StageNormalize
	}
	return strconv.FormatUint(value, 10), core.ReasonOK, StageNormalize
}

func CompareExactInt(given, correct string) (bool, core.ReasonCode, Stage) {
	if given == correct {
		return true, core.ReasonOK, StageCompare
	}
	return false, core.ReasonValueMismatch, StageCompare
}

// ValidateExactInt evaluates raw against the frozen correct answer stored for
// the task instance. The answer is parsed and normalized independently so a
// malformed frozen answer cannot accidentally grade as a valid mismatch.
func ValidateExactInt(raw, correctAnswer string) Result {
	parsed, reason, stage := ParseExactInt(raw)
	if reason != core.ReasonOK {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: reason, Stage: stage, CorrectAnswer: correctAnswer}
	}

	normalized, reason, stage := NormalizeExactInt(parsed)
	if reason != core.ReasonOK {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: reason, Stage: stage, CorrectAnswer: correctAnswer}
	}

	correctParsed, correctReason, _ := ParseExactInt(correctAnswer)
	if correctReason != core.ReasonOK {
		return Result{
			Verdict:       core.VerdictUnparseable,
			ReasonCode:    core.ReasonParseError,
			Normalized:    normalized,
			Stage:         StageCompare,
			CorrectAnswer: correctAnswer,
		}
	}
	correctNormalized, correctReason, _ := NormalizeExactInt(correctParsed)
	if correctReason != core.ReasonOK {
		return Result{
			Verdict:       core.VerdictUnparseable,
			ReasonCode:    core.ReasonParseError,
			Normalized:    normalized,
			Stage:         StageCompare,
			CorrectAnswer: correctAnswer,
		}
	}

	equal, compareReason, _ := CompareExactInt(normalized, correctNormalized)
	if equal {
		return Result{
			Verdict:       core.VerdictCorrect,
			ReasonCode:    core.ReasonOK,
			Normalized:    normalized,
			Stage:         StageVerdict,
			CorrectAnswer: correctAnswer,
		}
	}
	return Result{
		Verdict:       core.VerdictIncorrect,
		ReasonCode:    compareReason,
		Normalized:    normalized,
		Stage:         StageVerdict,
		CorrectAnswer: correctAnswer,
	}
}
