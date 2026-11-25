#!/bin/sh
# SessionStart hook: prints pstack's routing instruction as session context.
#   session-start.sh        Claude Code: plain text
#   session-start.sh agy    Antigravity: one JSON object with injectSteps
# Turn it off with PSTACK_SESSION_HOOK=off or a `session hook: off` line in
# the pstack model sheet that /setup-pstack writes. On Claude Code, a sheet
# committed at <repo>/.claude/pstack-models.md replaces the user's sheet.
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
runtime=${1:-claude}

if [ "$runtime" = agy ]; then
  sheet="$HOME/.gemini/config/pstack-models.md"
else
  sheet="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/pstack-models.md"
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    root=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null) || root=$CLAUDE_PROJECT_DIR
    [ ! -f "$root/.claude/pstack-models.md" ] || sheet="$root/.claude/pstack-models.md"
  fi
fi

off=0
[ "${PSTACK_SESSION_HOOK:-}" != off ] || off=1
if [ -f "$sheet" ] && grep -qix 'session hook: *off' "$sheet"; then off=1; fi

if [ "$runtime" = agy ]; then
  # Antigravity expects JSON on stdout, even when routing is off.
  if [ "$off" = 1 ]; then printf '{}\n'; exit 0; fi
  LC_ALL=C awk -f "$here/json.awk" -f "$here/agy-context.awk" "$here/routing-agy.md"
  exit 0
fi
[ "$off" = 1 ] || cat "$here/routing.md"
