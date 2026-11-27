#!/bin/sh
# Behavior tests for the session hook and install.sh. Everything runs in a
# throwaway home, so the real ~/.claude and ~/.codex are never touched.
#
#   tests/run.sh
set -eu
repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" CLAUDE_CONFIG_DIR="$tmp/home/.claude" CODEX_HOME="$tmp/home/.codex"
unset ASTACK_SESSION_HOOK CLAUDE_PROJECT_DIR
mkdir -p "$CLAUDE_CONFIG_DIR" "$CODEX_HOME"
fail=0

is() { # <name> <actual> <expected>
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fail=1; fi
}
routes() { # prints on when the hook injects routing, off when it stays quiet
  if [ -n "$(sh "$repo/hooks/session-start.sh" "$@")" ]; then echo on; else echo off; fi
}
sheet="$CLAUDE_CONFIG_DIR/astack-models.md"

is 'hook: no sheet routes' "$(routes)" on
is 'hook: env switch' "$(ASTACK_SESSION_HOOK=off routes)" off
printf 'session hook: on\n' > "$sheet";      is 'hook: sheet on' "$(routes)" on
printf 'session hook: off\n' > "$sheet";     is 'hook: sheet off' "$(routes)" off
printf 'Session Hook:  OFF\n' > "$sheet";    is 'hook: case and spacing' "$(routes)" off
printf 'session hook: off \n' > "$sheet";    is 'hook: trailing space' "$(routes)" off
printf 'session hook: off\r\n' > "$sheet";   is 'hook: CRLF line ending' "$(routes)" off
printf 'no session hook: off\n' > "$sheet";  is 'hook: other text on the line' "$(routes)" on
printf 'session hook: on\n' > "$sheet"
mkdir -p "$tmp/proj/.claude"
printf 'session hook: off\n' > "$tmp/proj/.claude/astack-models.md"
is 'hook: project sheet replaces the user sheet' "$(CLAUDE_PROJECT_DIR="$tmp/proj" routes)" off
is 'hook: Antigravity prints JSON when off' "$(ASTACK_SESSION_HOOK=off sh "$repo/hooks/session-start.sh" agy)" '{}'
rm "$sheet"

# install.sh runs from a copy, so the copy can move.
mkdir "$tmp/a"
cp -R "$repo/skills" "$repo/agents" "$repo/hooks" "$repo/install.sh" "$tmp/a/"
settings="$CLAUDE_CONFIG_DIR/settings.json"
count() { find "$CLAUDE_CONFIG_DIR/skills" "$CLAUDE_CONFIG_DIR/agents" "$CODEX_HOME/skills" -type l | wc -l | tr -d ' '; }
dead() { find "$CLAUDE_CONFIG_DIR" "$CODEX_HOME" -type l ! -exec test -e {} \; -print | wc -l | tr -d ' '; }
hooks() { grep -c 'session-start.sh' "$settings" || true; }

mkdir -p "$CLAUDE_CONFIG_DIR/skills/tdd"
echo mine > "$CLAUDE_CONFIG_DIR/skills/tdd/SKILL.md"
printf '# mine\n' > "$CODEX_HOME/AGENTS.md"
sh "$tmp/a/install.sh" >/dev/null 2>&1
links=$(count)
sh "$tmp/a/install.sh" >/dev/null 2>&1
is 'install: a rerun changes nothing' "$(count) $(hooks) $(grep -c 'routing: begin' "$CODEX_HOME/AGENTS.md")" "$links 1 1"
is "install: the user's own skill is kept" "$(cat "$CLAUDE_CONFIG_DIR/skills/tdd/SKILL.md")" mine

mv "$tmp/a" "$tmp/b"
sh "$tmp/b/install.sh" >/dev/null 2>&1
is 'move: every link is replaced' "$(count) $(dead)" "$links 0"
is 'move: one hook entry, at the new path' "$(hooks) $(grep -c "$tmp/b/hooks" "$settings")" '1 1'

mv "$tmp/b" "$tmp/c"
sh "$tmp/c/install.sh" --uninstall >/dev/null 2>&1
is 'uninstall after a move: no links, no hook' "$(count) $(hooks)" '0 0'
is "uninstall: the user's files are kept" "$(cat "$CLAUDE_CONFIG_DIR/skills/tdd/SKILL.md") $(cat "$CODEX_HOME/AGENTS.md")" 'mine # mine'

[ "$fail" = 0 ] || exit 1
echo "tests ok"
