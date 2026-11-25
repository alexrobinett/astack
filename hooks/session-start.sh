#!/bin/sh
# SessionStart hook: prints astack's routing instruction as session context.
#   session-start.sh        Claude Code: plain text
#   session-start.sh agy    Antigravity: one JSON object with injectSteps
# Turn it off with ASTACK_SESSION_HOOK=off or a `session hook: off` line in
# the astack model sheet that /setup-astack writes. On Claude Code, a sheet
# committed at <repo>/.claude/astack-models.md replaces the user's sheet.
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
runtime=${1:-claude}

if [ "$runtime" = agy ]; then
  sheet="$HOME/.gemini/config/astack-models.md"
else
  sheet="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/astack-models.md"
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    root=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null) || root=$CLAUDE_PROJECT_DIR
    [ ! -f "$root/.claude/astack-models.md" ] || sheet="$root/.claude/astack-models.md"
  fi
fi

off=0
[ "${ASTACK_SESSION_HOOK:-}" != off ] || off=1
# read-sheet.sh strips a BOM and CRLF endings and decodes UTF-16.
reader="$here/../skills/setup-astack/scripts/read-sheet.sh"
if [ -f "$sheet" ] && sh "$reader" "$sheet" 2>/dev/null |
  grep -qiE '^[[:space:]]*session hook:[[:space:]]*off[[:space:]]*$'; then off=1; fi

if [ "$runtime" = agy ]; then
  # Antigravity expects JSON on stdout, even when routing is off.
  if [ "$off" = 1 ]; then printf '{}\n'; exit 0; fi
  LC_ALL=C awk -f "$here/json.awk" -f "$here/agy-context.awk" "$here/routing-agy.md"
  exit 0
fi
[ "$off" = 1 ] || cat "$here/routing.md"
