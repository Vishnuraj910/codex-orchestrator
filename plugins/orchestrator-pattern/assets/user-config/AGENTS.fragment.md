## Global Orchestrator Pattern

Keep the main task focused on requirements, planning, user communication, judgment, and final verification. Delegate bounded, independent work when it reduces context noise or allows useful parallelism.

- Use `scout` for read-only exploration, retrieval, logs, inventories, and triage.
- Use `verifier` for tests, typechecks, builds, lint, and scripted QA; it does not fix failures.
- Use `implementer` for bounded changes from a written specification.
- Prefer native custom roles only when the spawn interface applies their role configuration. Otherwise use `${CODEX_HOME:-$HOME/.codex}/bin/codex-agent <role> <absolute-cwd> <task>`.
- Work inline for trivial actions or immediate blockers. Keep fan-out small, normally two or three workers.
- Never run concurrent writers against overlapping files or the same write scope.
- Give every worker an explicit scope, success criteria, prohibited actions, working directory, and compact return format.
- Treat worker completion as evidence that it stopped, not evidence that edits landed or checks passed.
- Independently inspect on-disk changes and material verification claims before reporting completion.
- Never promote a sample into an exhaustive or negative claim; state the verified evidence scope.
- Subagents inherit the user's authority and never expand it.
