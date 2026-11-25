#!/bin/sh
# Import pstack's skills and agents from a pstack-claude checkout, then adapt
# them for this repo: Claude Code and Codex only, plus the T3 Code mapping.
# Idempotent. Rerun after updating the checkout, then review the diff.
#
#   scripts/sync-pstack.sh <path-to-pstack-claude-checkout>
set -eu

src=${1:?usage: scripts/sync-pstack.sh <path-to-pstack-claude-checkout>}
plugin="$src/plugins/pstack"
[ -d "$plugin/skills/poteto-mode" ] || { echo "not a pstack-claude checkout: $src" >&2; exit 1; }
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
manifest="$root/skills/.pstack-skills"

# Skills tstack already covers. pstack's poteto-mode Babysit playbook already
# supersedes its standalone babysit skill; tstack's babysit-pr is T3-native.
skip="babysit"

# Remove the previous import, so skills deleted upstream disappear here too.
if [ -f "$manifest" ]; then
  while IFS= read -r name; do
    [ -n "$name" ] && rm -rf "$root/skills/$name"
  done < "$manifest"
fi
: > "$manifest"

for dir in "$plugin"/skills/*/; do
  name=$(basename "$dir")
  case " $skip " in *" $name "*) continue ;; esac
  [ -e "$root/skills/$name" ] && { echo "collision with a tstack skill: $name" >&2; exit 1; }
  cp -R "$dir" "$root/skills/$name"
  echo "$name" >> "$manifest"
done

# Plugin agents become Claude Code user agents (install.sh copies them).
rm -rf "$root/agents"
mkdir -p "$root/agents"
cp "$plugin"/agents/*.md "$root/agents/"
cp "$plugin"/agents/*.md "$root/skills/poteto-mode/references/agents/"

# Licenses and provenance travel with the import.
cp "$src/LICENSE" "$root/LICENSE-pstack"
cp "$src/LICENSE-cursor-team-kit" "$src/LICENSE-thermos" "$root/"
git -C "$src" rev-parse HEAD > "$root/skills/.pstack-commit" 2>/dev/null || true

# Keep Claude Code and Codex mappings. Drop the other harnesses.
refs="$root/skills/poteto-mode/references"
for f in pi-tools copilot-tools muse-tools minimax-tools agy-tools omp-tools kimi-tools grok dsh-tools opencode-tools; do
  rm -f "$refs/$f.md"
done
cp "$root/scripts/t3-tools.md" "$refs/t3-tools.md"

find "$root/skills" "$root/agents" -name '*.md' | while IFS= read -r f; do
  grep -q 'pstack\|poteto\|platform mapping\|babysit' "$f" || continue
  perl -0pi -e '
    # Per-skill preambles: drop other harnesses, add T3 Code after Codex.
    s/^On (?:GitHub Copilot|Muse|Antigravity|Pi|MiniMax Code|OMP|Kimi Code CLI|Grok Build|DeepSeek Harness|OpenCode 2), read the \[platform mapping\][^\n]*\n\n//mg;
    s/^(On Codex, read the \[platform mapping\]\(([^)]*)codex-tools\.md\)[^\n]*\n)/$1\nIn T3 Code, also read the [T3 Code mapping]($2t3-tools.md) before following this skill.\n/mg;
    # poteto-mode Platform Adaptation: Claude Code, Codex, T3 Code.
    s/ On Pi, read \[`references\/pi-tools\.md`\].*? On OpenCode 2, read \[`references\/opencode-tools\.md`\]\(references\/opencode-tools\.md\) instead\./ In T3 Code, on either provider, also read [`references\/t3-tools.md`](references\/t3-tools.md); it overrides the Claude Code and Codex defaults where they differ./s;
    # Plugin agent types install as user agents, without the plugin prefix.
    s/pstack:(poteto-agent|comment-sicko|thermo-nuclear-review-subagent|thermo-nuclear-code-quality-review-subagent)/$1/g;
    # The standalone babysit skill is tstack babysit-pr.
    s/the bundled \*\*babysit\*\* skill/the **babysit-pr** skill/g;
    s/\(\.\.\/babysit\/SKILL\.md\)/(..\/babysit-pr\/SKILL.md)/g;
    # Links to the dropped harness mappings keep their text, lose the link.
    s/\[([^\]]*)\]\([^)]*\/(?:pi-tools|copilot-tools|muse-tools|minimax-tools|agy-tools|omp-tools|kimi-tools|grok|dsh-tools|opencode-tools)\.md(?:#[^)]*)?\)/$1/g;
  ' "$f"
done

# The poteto-agent definition looks for poteto-mode in the plugin cache.
perl -0pi -e 's/With no path, before any other work, search .*? If no such file exists, stop and tell your parent\./With no path, read `\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/skills\/poteto-mode\/SKILL.md`, or `\${CODEX_HOME:-\$HOME\/.codex}\/skills\/poteto-mode\/SKILL.md` on Codex. If neither exists, stop and tell your parent./s' \
  "$root/agents/poteto-agent.md" "$refs/agents/poteto-agent.md"

# Routing context for the SessionStart hook and AGENTS.md.
perl -pe 's/`pstack:([a-z-]+)`/`$1`/g; s/You have pstack\./You have tstack with pstack routing./; s/the right pstack skill/the right skill/' \
  "$plugin/hooks/session-start-context.md" > "$root/hooks/routing.md"

echo "imported $(wc -l < "$manifest" | tr -d ' ') pstack skills from $(cat "$root/skills/.pstack-commit" 2>/dev/null || echo "$src")"
