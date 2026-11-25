#!/bin/sh
# SessionStart hook: prints pstack's routing instruction as session context.
# Turn it off with PSTACK_SESSION_HOOK=off or a `session hook: off` line in
# the pstack model sheet that /setup-pstack writes. A sheet committed at
# <repo>/.claude/pstack-models.md replaces the user's sheet in that project.
set -eu
[ "${PSTACK_SESSION_HOOK:-}" != off ] || exit 0
sheet="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/pstack-models.md"
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  root=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null) || root=$CLAUDE_PROJECT_DIR
  [ ! -f "$root/.claude/pstack-models.md" ] || sheet="$root/.claude/pstack-models.md"
fi
if [ -f "$sheet" ] && grep -qix 'session hook: *off' "$sheet"; then exit 0; fi
cat "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/routing.md"
