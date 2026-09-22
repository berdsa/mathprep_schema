package core

import (
	"context"
	"errors"
)

var ErrTaskTypeTemplateNotFound = errors.New("task type template not found")

type TaskTypeTemplateStore interface {
	FindTaskTypeTemplate(context.Context, string, Locale) (TaskTypeTemplate, bool, error)
	FindTaskTypeLocale(context.Context, string) (Locale, bool, error)
}

// LookupTaskTypeTemplate returns the requested translation when present. A
// missing translation falls back to the task type's primary locale.
func LookupTaskTypeTemplate(ctx context.Context, store TaskTypeTemplateStore, typeID string, locale Locale) (TaskTypeTemplate, error) {
	template, found, err := store.FindTaskTypeTemplate(ctx, typeID, locale)
	if err != nil {
		return TaskTypeTemplate{}, err
	}
	if found {
		return template, nil
	}
	primary, found, err := store.FindTaskTypeLocale(ctx, typeID)
	if err != nil {
		return TaskTypeTemplate{}, err
	}
	if found && primary != locale {
		template, found, err = store.FindTaskTypeTemplate(ctx, typeID, primary)
		if err != nil {
			return TaskTypeTemplate{}, err
		}
		if found {
			return template, nil
		}
	}
	return TaskTypeTemplate{}, ErrTaskTypeTemplateNotFound
}
