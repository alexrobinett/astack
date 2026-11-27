#!/bin/sh
# Check the tree that scripts/sync-pstack.sh leaves. sync-pstack.sh rewrites
# pstack's prose with patterns, and a pattern that stops matching upstream
# does nothing. Each check below catches text such a miss leaves behind.
#
#   scripts/check.sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
fail=0

leftover() { # <what> <extended regex>
  if hits=$(grep -rnIE --exclude-dir=node_modules -- "$2" skills agents hooks); then
    echo "check: $1" >&2
    printf '%s\n' "$hits" | cut -c1-200 | sed 's/^/  /' >&2
    fail=1
  fi
}

leftover 'a plugin-prefixed name' 'pstack:[a-z]'
leftover 'a plugin path' '<plugin>/|under the installed plugin'
leftover 'a poteto-* entry point' 'poteto-(mode|help|agent)'
leftover 'a pstack setup name' 'setup-pstack|pstack-models|PSTACK_SESSION_HOOK'
leftover 'a mapping for a dropped harness' '(pi|copilot|muse|minimax|omp|kimi|dsh|opencode)-tools\.md|copilot\.md'
leftover 'the standalone babysit skill' '\.\./babysit/'

for list in skills/.pstack-skills agents/.pstack-agents; do
  dir=$(dirname "$list")
  while IFS= read -r name; do
    [ -e "$dir/$name" ] || { echo "check: $list names $name, which is missing" >&2; fail=1; }
  done < "$list"
done

for f in skills/bunny-mode/SKILL.md skills/bunny-mode/references/t3-tools.md; do
  grep -q 'tstack-skills\.md' "$f" || { echo "check: $f does not point at tstack-skills.md" >&2; fail=1; }
done

# Every relative Markdown link under skills/ and agents/ resolves.
node - skills agents <<'JS' || fail=1
const fs = require("fs");
const path = require("path");
let broken = 0;
const walk = (dir) => {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === "node_modules") continue;
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (entry.name.endsWith(".md")) check(file);
  }
};
const check = (file) => {
  const text = fs.readFileSync(file, "utf8").replace(/```[\s\S]*?```/g, "");
  for (const [, link] of text.matchAll(/\[[^\]]*\]\(([^)\s]+)\)/g)) {
    if (/^(https?:|mailto:|#|<)/.test(link) || /[${]/.test(link)) continue;
    const target = link.split("#")[0];
    if (target && !fs.existsSync(path.join(path.dirname(file), target))) {
      console.error(`check: broken link in ${file}: ${link}`);
      broken++;
    }
  }
};
process.argv.slice(2).forEach(walk);
process.exit(broken ? 1 : 0);
JS

[ "$fail" = 0 ] || exit 1
echo "check ok"
