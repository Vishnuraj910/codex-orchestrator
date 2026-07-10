# Setup and compatibility

## Model defaults

| Role | Model | Reasoning | Mutation policy |
| --- | --- | --- | --- |
| Orchestrator | `gpt-5.6-sol` | `xhigh` | Current task permissions |
| Scout | `gpt-5.6-terra` | `xhigh` | Read-only |
| Verifier | `gpt-5.6-terra` | `xhigh` | Checks only |
| Implementer | `gpt-5.6-sol` | `high` | Workspace writes |

Override any model or effort during installation:

```bash
SCOUT_MODEL=gpt-5.6-terra \
SCOUT_EFFORT=high \
IMPLEMENTER_MODEL=gpt-5.6 \
bash ../../scripts/install-user-config.sh
```

Supported effort values are `none`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`; the selected model must support the chosen value.

## Native roles and the dispatcher

Codex can load custom agents from `~/.codex/agents/`, but not every collaboration surface exposes an explicit role or model override. A spawned task named `scout` may still inherit the root model.

Use a native role only when the spawn tool applies the role configuration. Otherwise use the installed dispatcher, which starts an ephemeral `codex exec` session with the matching profile and returns only its final report:

```bash
"${CODEX_HOME:-$HOME/.codex}/bin/codex-agent" <role> <absolute-cwd> <task>
```

## Hook trust

Codex requires users to review and trust non-managed command hooks. Open a fresh Codex CLI session, enter `/hooks`, inspect the Orchestrator Pattern hook, and trust it. The hook is advisory: it emits reminders and never blocks a tool call.

## Troubleshooting

- Run `codex doctor --json` and inspect `checks.config.load` when configuration fails.
- Run `codex --profile orchestrator` to start the CLI with the pinned root profile.
- Run the dispatcher directly to isolate worker-profile problems.
- Use absolute working directories with the dispatcher.
- Reinstall with `--force` only after reviewing the timestamped backup printed by the installer.
