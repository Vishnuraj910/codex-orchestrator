# Codex Orchestrator Pattern

An installable Codex plugin for keeping the root task focused while scoped workers handle exploration, implementation, and verification.

```text
Root orchestrator
├── scout       read-only discovery and triage
├── implementer bounded code changes from a written spec
└── verifier    tests, typechecks, builds, lint, and QA
```

The pattern protects the root context from raw logs and broad searches, prevents overlapping writers, requires evidence-scoped worker reports, and independently verifies delegated work.

## Install from GitHub

After this repository is published, replace `OWNER/REPOSITORY` with its GitHub path:

```bash
codex plugin marketplace add OWNER/REPOSITORY
codex plugin add orchestrator-pattern@codex-orchestrator
```

Start a new Codex task and run:

```text
Use $orchestrator-pattern to install the global worker profiles and configure the orchestrator pattern.
```

Then open `/hooks`, review the advisory hook, trust it, and start another new task.

## Install from a local clone

```bash
git clone <repository-url>
cd Orchestrator
./install.sh
```

The local installer registers this checkout as a marketplace, installs the plugin, installs model-pinned profiles beneath `CODEX_HOME`, and adds a marked section to the global `AGENTS.md`. Existing different files are never overwritten without `--force`, and replacements are backed up.

To install only one layer:

```bash
./install.sh --plugin-only
./install.sh --user-config-only
```

## Use it

Explicit skill invocation:

```text
Use $orchestrator-pattern to implement this feature. Delegate discovery, implementation, and verification where useful.
```

Start the CLI with the pinned root profile:

```bash
codex --profile orchestrator
```

Run a pinned worker directly:

```bash
"${CODEX_HOME:-$HOME/.codex}/bin/codex-agent" scout "$PWD" \
  "Find the request path and return conclusions with file:line evidence."
```

## Default model routing

| Role | Default model | Reasoning | Policy |
| --- | --- | --- | --- |
| Orchestrator | `gpt-5.6-sol` | `xhigh` | Own decisions and final verification |
| Scout | `gpt-5.6-terra` | `xhigh` | Read-only |
| Verifier | `gpt-5.6-terra` | `xhigh` | Checks only |
| Implementer | `gpt-5.6-sol` | `high` | Bounded workspace writes |

Override models without editing templates:

```bash
ORCHESTRATOR_MODEL=gpt-5.6 \
IMPLEMENTER_MODEL=gpt-5.6 \
SCOUT_EFFORT=high \
./install.sh --user-config-only
```

Model names and supported reasoning levels vary by account and Codex release. Choose models available in your environment.

## What gets installed

- Plugin skill: orchestration workflow and evidence contract.
- Advisory `PreToolUse` hook: reminds the root task when bulk work is a delegation candidate; it never blocks.
- Custom agent definitions under `~/.codex/agents/`.
- CLI profiles and a portable dispatcher under `~/.codex/`.
- A marked global `AGENTS.md` section that can be removed safely.

`CODEX_HOME` is respected when it is set; otherwise the installer uses `~/.codex`.

## Compatibility note

Some Codex collaboration surfaces expose an explicit custom-agent role; others currently expose only a task label and inherit the root model. The bundled dispatcher is the fallback that guarantees the selected worker profile. Native role support can be used automatically when the active spawn interface applies it.

The hook is advisory because current Codex hook interception does not cover every possible tool path. The orchestration skill and global instructions remain the primary behavior layer.

## Security

- Workers inherit the user's authority; delegation never grants additional permission.
- The scout profile is read-only.
- Worker profiles disable nested agents to prevent recursive fan-out.
- The installer writes only beneath `CODEX_HOME` and creates timestamped backups before replacement.
- The hook reads one tool-call payload from standard input, emits an optional warning, and does not persist it.

## Uninstall

From a clone or installed plugin source:

```bash
./plugins/orchestrator-pattern/scripts/uninstall-user-config.sh
codex plugin remove orchestrator-pattern
codex plugin marketplace remove codex-orchestrator
```

Modified managed files are preserved unless `uninstall-user-config.sh --force` is used.

## Validate before publishing

```bash
python3 scripts/validate.py
```

The repository uses the MIT license. Contributions should preserve generic paths, configurable models, compact worker returns, and the root task's responsibility for final judgment.

## Codex documentation

- [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Build plugins](https://learn.chatgpt.com/docs/build-plugins)
- [Build skills](https://learn.chatgpt.com/docs/build-skills)
- [Hooks](https://learn.chatgpt.com/docs/hooks)
