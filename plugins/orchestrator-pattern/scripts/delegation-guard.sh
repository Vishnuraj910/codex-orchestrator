#!/bin/sh
# Advisory only. Never blocks and never persists the tool payload.

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // .tool // empty' 2>/dev/null)
command=$(printf '%s' "$input" | jq -r '
  .tool_input.command // .tool_input.cmd //
  .input.command // .input.cmd //
  (if (.tool_input | type) == "string" then .tool_input else empty end) //
  (if (.input | type) == "string" then .input else empty end) // empty
' 2>/dev/null)
file_path=$(printf '%s' "$input" | jq -r '
  .tool_input.file_path // .tool_input.path //
  .input.file_path // .input.path // empty
' 2>/dev/null)
codex_home=${CODEX_HOME:-"$HOME/.codex"}
dispatcher="$codex_home/bin/codex-agent"
warning=""

case "$tool" in
  Read|read_file)
    if [ -n "$file_path" ] && [ -f "$file_path" ]; then
      size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || printf '0')
      if [ "${size:-0}" -gt 40960 ]; then
        warning="orchestrator-pattern: this direct read targets a file larger than 40 KB ($((size / 1024)) KB). Delegate bulk inspection with $dispatcher scout <absolute-cwd> <task>, or read only the required slice. Ignore inside an already delegated worker."
      fi
    fi
    ;;
  Bash|shell|exec_command|functions.exec)
    if printf '%s' "$command" | grep -Eq '(grep[[:space:]]+-[^[:space:]]*r|rg[^\n]*(--context|-A[[:space:]]*[0-9]|-B[[:space:]]*[0-9]|-C[[:space:]]*[0-9])|tail[[:space:]]+-n[[:space:]]*[3-9][0-9]{2,}|curl[[:space:]]|wget[[:space:]]|yt-dlp|find[[:space:]]+/)'; then
      warning="orchestrator-pattern: this looks like bulk retrieval or exploration. Delegate the bounded search and retry loop with $dispatcher scout <absolute-cwd> <task>, and require compact evidence rather than raw output. Ignore inside an already delegated worker."
    elif printf '%s' "$command" | grep -Eq '(^|[[:space:]])(pytest|vitest|jest|cargo[[:space:]]+test|go[[:space:]]+test|mvn[[:space:]].*test|gradle[[:space:]].*test|tsc[[:space:]].*--noEmit)([[:space:]]|$)|((pnpm|npm|yarn)[^\n]*(test|typecheck|lint|build))'; then
      warning="orchestrator-pattern: this check may produce substantial output. Prefer $dispatcher verifier <absolute-cwd> <task> unless the result is an immediate root-task dependency. Ignore inside an already delegated worker."
    fi
    ;;
esac

if [ -n "$warning" ]; then
  jq -cn --arg message "$warning" '{systemMessage:$message}'
fi

exit 0
