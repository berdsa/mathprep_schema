package core

import (
	"context"
	"errors"
	"testing"
)

type templateStoreStub struct {
	templates map[Locale]TaskTypeTemplate
	primary   Locale
}

func (s templateStoreStub) FindTaskTypeTemplate(_ context.Context, _ string, locale Locale) (TaskTypeTemplate, bool, error) {
	t, ok := s.templates[locale]
	return t, ok, nil
}
func (s templateStoreStub) FindTaskTypeLocale(context.Context, string) (Locale, bool, error) {
	return s.primary, s.primary != "", nil
}

func TestLookupTaskTypeTemplateUsesRequestedLocale(t *testing.T) {
	want := TaskTypeTemplate{TypeID: "G3-NUM-002", Locale: "en-US", RenderTarget: RenderTargetPlaintext, TemplateText: "{{a}} × {{b}} = ?", SpecVersion: "1.0.0-draft"}
	got, err := LookupTaskTypeTemplate(context.Background(), templateStoreStub{templates: map[Locale]TaskTypeTemplate{"en-US": want}, primary: LocaleRuKZ}, "G3-NUM-002", "en-US")
	if err != nil || got != want {
		t.Fatalf("got %#v, err %v", got, err)
	}
}

func TestLookupTaskTypeTemplateFallsBackToPrimaryLocale(t *testing.T) {
	want := TaskTypeTemplate{TypeID: "G3-NUM-002", Locale: LocaleRuKZ, RenderTarget: RenderTargetPlaintext, TemplateText: "{{a}} × {{b}} = ?", SpecVersion: "1.0.0-draft"}
	got, err := LookupTaskTypeTemplate(context.Background(), templateStoreStub{templates: map[Locale]TaskTypeTemplate{LocaleRuKZ: want}, primary: LocaleRuKZ}, "G3-NUM-002", "kk-KZ")
	if err != nil || got != want {
		t.Fatalf("got %#v, err %v", got, err)
	}
}

func TestLookupTaskTypeTemplateReportsMissingTemplate(t *testing.T) {
	_, err := LookupTaskTypeTemplate(context.Background(), templateStoreStub{primary: LocaleRuKZ}, "G3-NUM-002", LocaleRuKZ)
	if !errors.Is(err, ErrTaskTypeTemplateNotFound) {
		t.Fatalf("err = %v", err)
	}
}
