#!/bin/sh
# SessionStart hook: prints pstack's routing instruction as session context.
# Turn it off with PSTACK_SESSION_HOOK=off or a `session hook: off` line in
# the pstack model sheet that /setup-pstack writes.
set -eu
sheet="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/pstack-models.md"
[ "${PSTACK_SESSION_HOOK:-}" != off ] || exit 0
if [ -f "$sheet" ] && grep -qix 'session hook: *off' "$sheet"; then exit 0; fi
cat "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/routing.md"
