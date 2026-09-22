# Task-type template infrastructure

Phase A adds migration `000010_task_type_templates`. `task_type_template` stores one template per `(type_id, locale, spec_version)` and enforces both dictionary-backed locales and task-type ownership.

`pkg/core.LookupTaskTypeTemplate` first checks the requested locale, then the locale declared by `task_type`. A missing translation therefore falls back to the primary locale; a missing template for both locales remains an explicit configuration error.

The migration seeds only the five-type taskgen pilot with the existing English wording. These rows are infrastructure fixtures, not the Russian translation backfill requested for Phase B.
