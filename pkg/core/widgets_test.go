package core

import "testing"

func TestAnswerWidgetDictionaryValues(t *testing.T) {
	got := []AnswerWidget{
		AnswerWidgetNumeric, AnswerWidgetFraction, AnswerWidgetChoice,
		AnswerWidgetTupleN, AnswerWidgetSetList, AnswerWidgetMatrixGrid,
		AnswerWidgetStructuredCanon, AnswerWidgetExpression,
	}
	want := []AnswerWidget{"NUMERIC", "FRACTION", "CHOICE", "TUPLE_N", "SET_LIST", "MATRIX_GRID", "STRUCTURED_CANON", "EXPRESSION"}
	if len(got) != len(want) {
		t.Fatalf("got %d widgets, want %d", len(got), len(want))
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("widget[%d] = %q, want %q", i, got[i], want[i])
		}
	}
	if RenderTargetLatex != "latex" {
		t.Fatalf("latex render target = %q", RenderTargetLatex)
	}
}
