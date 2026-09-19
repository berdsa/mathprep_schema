# Agent log

## 2026-09-19 — Repository initialization

- Confirmed this is the canonical `mathprep-schema` repository and retained all thirteen SRD artifacts directly under `docs/srd/`.
- Replaced the misplaced `pkg/core` guidance with the repository-wide `AGENTS.md` template, consistent with ADR-007 and the SRD.
- Added this append-only agent log.
- Checked Graphify usage; its current CLI requires `graphify update .` for the requested repository graph refresh.
- Local PostgreSQL initialization is pending: `POSTGRES_PASSWORD` was not present in the shell, so the documented container was not created and no credential was invented or stored.
