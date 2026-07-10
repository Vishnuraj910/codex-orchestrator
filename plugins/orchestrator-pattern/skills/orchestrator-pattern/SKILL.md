---
name: orchestrator-pattern
description: Coordinate complex Codex work through scoped scout, verifier, and implementer workers, compact evidence returns, model routing, and root-level verification. Use when the user asks for orchestration, delegation, parallel agents, worker roles, context-efficient exploration, or a multi-step task that benefits from separating discovery, implementation, and verification.
---

# Orchestrator Pattern

Keep the root task focused on requirements, decisions, user communication, and final verification. Move bounded, noisy work into workers that return compact evidence.

## Set up global worker profiles

When the user explicitly asks to install or configure the pattern globally, run:

```bash
bash ../../scripts/install-user-config.sh
```

Resolve the path relative to this `SKILL.md`. The installer writes only beneath `CODEX_HOME` (default `~/.codex`), backs up collisions, and refuses to overwrite different files unless the user approves `--force`.

After setup, tell the user to review the plugin hook with `/hooks` and start a new task. Read [setup-and-compatibility.md](references/setup-and-compatibility.md) when installation, model customization, native-role compatibility, or troubleshooting is relevant.

## Orchestrate a task

1. Define the objective, scope, success criteria, prohibited actions, and required checks.
2. Keep immediate blockers and final judgment in the root task.
3. Delegate only bounded work that is independent, noisy, retry-prone, or expected to produce substantial output.
4. Assign one role per subtask:
   - `scout`: read-only discovery, retrieval, logs, inventory, and triage.
   - `verifier`: tests, typechecks, builds, lint, and scripted QA; never fix failures.
   - `implementer`: bounded edits from a written specification; never broaden scope.
5. Prefer native custom roles when the spawn interface accepts an explicit role and applies its model configuration.
6. Otherwise use the pinned dispatcher at `${CODEX_HOME:-$HOME/.codex}/bin/codex-agent`:

```bash
"${CODEX_HOME:-$HOME/.codex}/bin/codex-agent" scout "$PWD" "Find the code path and return file:line evidence."
```

7. Parallelize only independent work. Never assign overlapping write sets to concurrent implementers.
8. Wait for required results, judge the evidence, and resolve contradictions in the root task.
9. Independently inspect on-disk changes and run or review the required verification before reporting completion.

## Evidence contract

- Require each worker to state what it inspected and what remains unverified.
- Never promote a sample into an exhaustive or negative claim.
- Treat completion notifications as proof that a worker stopped, not proof that edits landed or checks passed.
- Distinguish verified facts from hypotheses.
- Do not let delegation expand the user's permissions or authorize external mutations.

## Keep delegation proportional

Work inline for a single quick command, a trivial edit, or a hard dependency for the next decision. Delegate exploration likely to touch several files, large test output, retry loops, or a clearly specified implementation slice. Keep fan-out small—normally two or three workers—and prefer compact final reports over raw logs.
