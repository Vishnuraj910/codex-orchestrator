#!/bin/bash
set -euo pipefail

force=false
if [ "${1:-}" = "--force" ]; then force=true; elif [ "$#" -gt 0 ]; then printf 'Usage: uninstall-user-config.sh [--force]\n' >&2; exit 64; fi

codex_home=${CODEX_HOME:-"$HOME/.codex"}
manifest="$codex_home/.orchestrator-pattern-manifest"
hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi
}

if [ -f "$manifest" ]; then
  while IFS=$'\t' read -r expected relative; do
    target="$codex_home/$relative"
    [ -f "$target" ] || continue
    actual=$(hash_file "$target")
    if [ "$actual" = "$expected" ] || [ "$force" = true ]; then rm -f "$target"; printf 'Removed %s\n' "$target"; else printf 'Preserved modified file: %s\n' "$target" >&2; fi
  done <"$manifest"
  rm -f "$manifest"
else
  printf 'Install manifest not found; worker files were not removed.\n' >&2
fi

agents_file="$codex_home/AGENTS.md"
if [ -f "$agents_file" ]; then
  temporary=$(mktemp "${TMPDIR:-/tmp}/orchestrator-agents.XXXXXX")
  trap 'rm -f "$temporary"' EXIT
  awk -v start='<!-- orchestrator-pattern:start -->' -v end='<!-- orchestrator-pattern:end -->' '$0 == start { skip=1; next } $0 == end { skip=0; next } !skip { print }' "$agents_file" >"$temporary"
  cp "$temporary" "$agents_file"
fi

printf 'Removed managed Orchestrator Pattern configuration from %s\n' "$codex_home"
