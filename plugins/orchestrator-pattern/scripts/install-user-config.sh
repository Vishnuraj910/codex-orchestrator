#!/bin/bash
set -eo pipefail

force=false
skip_agents_md=false
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    --skip-agents-md) skip_agents_md=true ;;
    -h|--help) printf 'Usage: install-user-config.sh [--force] [--skip-agents-md]\n'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 64 ;;
  esac
done

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
template_root="$plugin_root/assets/user-config"
codex_home=${CODEX_HOME:-"$HOME/.codex"}

ORCHESTRATOR_MODEL=${ORCHESTRATOR_MODEL:-gpt-5.6-sol}
ORCHESTRATOR_EFFORT=${ORCHESTRATOR_EFFORT:-xhigh}
SCOUT_MODEL=${SCOUT_MODEL:-gpt-5.6-terra}
SCOUT_EFFORT=${SCOUT_EFFORT:-xhigh}
VERIFIER_MODEL=${VERIFIER_MODEL:-gpt-5.6-terra}
VERIFIER_EFFORT=${VERIFIER_EFFORT:-xhigh}
IMPLEMENTER_MODEL=${IMPLEMENTER_MODEL:-gpt-5.6-sol}
IMPLEMENTER_EFFORT=${IMPLEMENTER_EFFORT:-high}

validate_model() {
  case "$1" in *[!A-Za-z0-9._:/-]*|'') printf 'Invalid model identifier: %s\n' "$1" >&2; exit 64 ;; esac
}
validate_effort() {
  case "$1" in none|minimal|low|medium|high|xhigh|max|ultra) ;; *) printf 'Invalid reasoning effort: %s\n' "$1" >&2; exit 64 ;; esac
}
for model in "$ORCHESTRATOR_MODEL" "$SCOUT_MODEL" "$VERIFIER_MODEL" "$IMPLEMENTER_MODEL"; do validate_model "$model"; done
for effort in "$ORCHESTRATOR_EFFORT" "$SCOUT_EFFORT" "$VERIFIER_EFFORT" "$IMPLEMENTER_EFFORT"; do validate_effort "$effort"; done

stage=$(mktemp -d "${TMPDIR:-/tmp}/orchestrator-pattern.XXXXXX")
trap 'rm -rf "$stage"' EXIT

render() {
  local source=$1 destination=$2
  mkdir -p "$(dirname "$destination")"
  sed \
    -e "s|__ORCHESTRATOR_MODEL__|$ORCHESTRATOR_MODEL|g" \
    -e "s|__ORCHESTRATOR_EFFORT__|$ORCHESTRATOR_EFFORT|g" \
    -e "s|__SCOUT_MODEL__|$SCOUT_MODEL|g" \
    -e "s|__SCOUT_EFFORT__|$SCOUT_EFFORT|g" \
    -e "s|__VERIFIER_MODEL__|$VERIFIER_MODEL|g" \
    -e "s|__VERIFIER_EFFORT__|$VERIFIER_EFFORT|g" \
    -e "s|__IMPLEMENTER_MODEL__|$IMPLEMENTER_MODEL|g" \
    -e "s|__IMPLEMENTER_EFFORT__|$IMPLEMENTER_EFFORT|g" \
    "$source" >"$destination"
}

render "$template_root/agents/scout.toml.tmpl" "$stage/agents/scout.toml"
render "$template_root/agents/verifier.toml.tmpl" "$stage/agents/verifier.toml"
render "$template_root/agents/implementer.toml.tmpl" "$stage/agents/implementer.toml"
render "$template_root/profiles/orchestrator.config.toml.tmpl" "$stage/orchestrator.config.toml"
render "$template_root/profiles/scout.config.toml.tmpl" "$stage/scout.config.toml"
render "$template_root/profiles/verifier.config.toml.tmpl" "$stage/verifier.config.toml"
render "$template_root/profiles/implementer.config.toml.tmpl" "$stage/implementer.config.toml"
mkdir -p "$stage/bin"
cp "$plugin_root/scripts/codex-agent" "$stage/bin/codex-agent"

targets=(agents/scout.toml agents/verifier.toml agents/implementer.toml orchestrator.config.toml scout.config.toml verifier.config.toml implementer.config.toml bin/codex-agent)
conflicts=()
for relative in "${targets[@]}"; do
  target="$codex_home/$relative"
  if [ -f "$target" ] && ! cmp -s "$stage/$relative" "$target"; then conflicts+=("$target"); fi
done
if [ "${#conflicts[@]}" -gt 0 ] && [ "$force" != true ]; then
  printf 'Refusing to overwrite different files:\n' >&2
  printf '  %s\n' "${conflicts[@]}" >&2
  printf 'Review them, then rerun with --force to create backups and replace them.\n' >&2
  exit 73
fi

timestamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="$codex_home/backups/orchestrator-pattern-$timestamp"
mkdir -p "$backup_dir"
for relative in "${targets[@]}"; do
  target="$codex_home/$relative"
  if [ -f "$target" ]; then mkdir -p "$backup_dir/$(dirname "$relative")"; cp -p "$target" "$backup_dir/$relative"; fi
  mkdir -p "$(dirname "$target")"
  cp "$stage/$relative" "$target"
done
chmod 755 "$codex_home/bin/codex-agent"

start_marker='<!-- orchestrator-pattern:start -->'
end_marker='<!-- orchestrator-pattern:end -->'
agents_file="$codex_home/AGENTS.md"
if [ "$skip_agents_md" != true ]; then
  if [ -f "$agents_file" ]; then
    cp -p "$agents_file" "$backup_dir/AGENTS.md"
    awk -v start="$start_marker" -v end="$end_marker" '$0 == start { skip=1; next } $0 == end { skip=0; next } !skip { print }' "$agents_file" >"$stage/AGENTS.clean"
  else
    : >"$stage/AGENTS.clean"
  fi
  {
    cat "$stage/AGENTS.clean"
    if [ -s "$stage/AGENTS.clean" ]; then printf '\n'; fi
    printf '%s\n' "$start_marker"
    cat "$template_root/AGENTS.fragment.md"
    printf '%s\n' "$end_marker"
  } >"$stage/AGENTS.md"
  mkdir -p "$codex_home"
  cp "$stage/AGENTS.md" "$agents_file"
fi

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}
manifest="$codex_home/.orchestrator-pattern-manifest"
: >"$manifest"
for relative in "${targets[@]}"; do printf '%s\t%s\n' "$(hash_file "$codex_home/$relative")" "$relative" >>"$manifest"; done

printf 'Installed Orchestrator Pattern user configuration in %s\n' "$codex_home"
printf 'Backup directory: %s\n' "$backup_dir"
printf 'Start the CLI with: codex --profile orchestrator\n'
