#!/bin/sh
# Link this checkout's skills and agents into Claude Code and Codex, and wire
# up pstack routing. Idempotent. `git pull` in this checkout updates the
# installed skills, because they are links.
#
#   ./install.sh            # Claude Code, plus Codex when ~/.codex exists
#   ./install.sh --uninstall
set -eu
repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
claude="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
codex="${CODEX_HOME:-$HOME/.codex}"
hook="$repo/hooks/session-start.sh"
begin='<!-- tstack routing: begin -->'
end='<!-- tstack routing: end -->'

link_dir() { # <source-dir> <dest-dir>
  mkdir -p "$2"
  for src in "$1"/*; do
    dest="$2/$(basename "$src")"
    if [ -L "$dest" ] || [ ! -e "$dest" ]; then
      ln -sfn "$src" "$dest"
    else
      echo "skip $dest: exists and is not a link (move it away to install)" >&2
    fi
  done
}

unlink_dir() { # <source-dir> <dest-dir>
  for src in "$1"/*; do
    dest="$2/$(basename "$src")"
    [ "$(readlink "$dest" 2>/dev/null)" = "$src" ] && rm "$dest"
  done
  return 0
}

settings_hook() { # add|remove
  node - "$claude/settings.json" "$hook" "$1" <<'JS'
const fs = require("fs");
const [file, hook, mode] = process.argv.slice(2);
const settings = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
const hooks = (settings.hooks ??= {});
const ours = (entry) => (entry.hooks ?? []).some((h) => h.command?.includes(hook));
hooks.SessionStart = (hooks.SessionStart ?? []).filter((entry) => !ours(entry));
if (mode === "add") {
  hooks.SessionStart.push({
    matcher: "startup|resume|clear|compact",
    hooks: [{ type: "command", command: `"${hook}"`, statusMessage: "Loading pstack routing" }],
  });
}
if (hooks.SessionStart.length === 0) delete hooks.SessionStart;
fs.writeFileSync(file, JSON.stringify(settings, null, 2) + "\n");
JS
}

agents_block() { # add|remove
  file="$codex/AGENTS.md"
  [ -f "$file" ] || [ "$1" = add ] || return 0
  touch "$file"
  awk -v b="$begin" -v e="$end" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$file" > "$file.tmp"
  if [ "$1" = add ]; then
    { cat "$file.tmp"; printf '%s\n' "$begin"; cat "$repo/hooks/routing.md"; printf '%s\n' "$end"; } > "$file"
    rm "$file.tmp"
  else
    mv "$file.tmp" "$file"
  fi
}

if [ "${1:-}" = --uninstall ]; then
  unlink_dir "$repo/skills" "$claude/skills"
  unlink_dir "$repo/agents" "$claude/agents"
  settings_hook remove
  if [ -d "$codex" ]; then unlink_dir "$repo/skills" "$codex/skills"; agents_block remove; fi
  echo "tstack uninstalled"
  exit 0
fi

link_dir "$repo/skills" "$claude/skills"
link_dir "$repo/agents" "$claude/agents"
settings_hook add
echo "Claude Code: skills, agents, and the routing hook installed"
if [ -d "$codex" ]; then
  link_dir "$repo/skills" "$codex/skills"
  agents_block add
  echo "Codex: skills and the AGENTS.md routing block installed"
fi
if command -v claude >/dev/null 2>&1 && claude plugin list 2>/dev/null | grep -q 'pstack@'; then
  echo "note: the pstack plugin is also installed, so every pstack skill loads twice." >&2
  echo "      remove it with: claude plugin uninstall pstack@pstack-claude" >&2
fi
command -v bun >/dev/null 2>&1 || echo "note: bun is not installed; the Shipping playbook stops at merge-ready without it." >&2
