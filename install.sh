#!/bin/bash
set -eo pipefail

install_plugin=true
install_user_config=true
force=false

for arg in "$@"; do
  case "$arg" in
    --plugin-only) install_user_config=false ;;
    --user-config-only) install_plugin=false ;;
    --force) force=true ;;
    -h|--help) printf 'Usage: ./install.sh [--plugin-only|--user-config-only] [--force]\n'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 64 ;;
  esac
done

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
plugin_root="$repo_root/plugins/orchestrator-pattern"

if [ "$install_plugin" = true ]; then
  if ! command -v codex >/dev/null 2>&1; then printf 'Codex CLI is required to install the plugin.\n' >&2; exit 69; fi
  if ! codex plugin marketplace list --json | grep -Fq "\"root\": \"$repo_root\""; then codex plugin marketplace add "$repo_root"; fi
  codex plugin add orchestrator-pattern@codex-orchestrator
fi

if [ "$install_user_config" = true ]; then
  if [ "$force" = true ]; then "$plugin_root/scripts/install-user-config.sh" --force; else "$plugin_root/scripts/install-user-config.sh"; fi
fi

printf '\nInstallation complete.\n'
printf '1. Start a new Codex CLI session.\n'
printf '2. Run /hooks and trust the Orchestrator Pattern hook.\n'
printf '3. Start with: codex --profile orchestrator\n'
