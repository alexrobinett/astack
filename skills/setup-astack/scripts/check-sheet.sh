#!/bin/sh
# Checks a pstack model sheet: every role has a line, every entry is
# inherit-parent, auto, or a model ID with an optional effort, and each panel
# names models from two vendors unless the sheet has `panel vendors: any`.
# Prints `sheet ok`, or `sheet invalid: <problems>` and exits 1.
# Usage: check-sheet.sh [sheet]
# The default sheet is the Claude Code user sheet.
set -eu
sheet=${1:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/astack-models.md}
if [ ! -f "$sheet" ] || [ ! -r "$sheet" ]; then
  echo "sheet invalid: cannot read $sheet"
  exit 1
fi
dir=$(cd "$(dirname "$0")" && pwd)
if ! normalized=$(sh "$dir/read-sheet.sh" "$sheet"); then
  echo "sheet invalid: cannot decode $sheet"
  exit 1
fi
printf '%s\n' "$normalized" | LC_ALL=C awk -f "$dir/sheet.awk" -f "$dir/check-sheet.awk"
