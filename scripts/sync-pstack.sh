#!/bin/sh
# Import pstack's skills and agents from a pstack-claude checkout, then adapt
# them for this repo: Claude Code and Codex only, plus the T3 Code mapping.
# Idempotent. Rerun after updating the checkout, then review the diff. It ends
# by running scripts/check.sh, which fails when an adaptation did not apply.
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

agents_manifest="$root/agents/.pstack-agents"
touch "$manifest"
mkdir -p "$root/agents"
touch "$agents_manifest"

# Check for collisions with tstack's own skills and agents before changing
# anything, so a failed sync leaves the tree as it was.
for path in "$plugin"/skills/*/ "$plugin"/agents/*.md; do
  name=$(basename "$path")
  case " $skip " in *" $name "*) continue ;; esac
  case "$path" in
    */agents/*) dest="$root/agents/$name"; list="$agents_manifest" ;;
    *) dest="$root/skills/$name"; list="$manifest" ;;
  esac
  if [ -e "$dest" ] && ! grep -qxF "$name" "$list"; then
    echo "collision with a tstack file: $dest" >&2
    exit 1
  fi
done

# Remove the previous import, so files deleted upstream disappear here too.
while IFS= read -r name; do
  [ -n "$name" ] && rm -rf "$root/skills/$name"
done < "$manifest"
while IFS= read -r name; do
  [ -n "$name" ] && rm -f "$root/agents/$name"
done < "$agents_manifest"
: > "$manifest"
: > "$agents_manifest"

for dir in "$plugin"/skills/*/; do
  name=$(basename "$dir")
  case " $skip " in *" $name "*) continue ;; esac
  cp -R "$dir" "$root/skills/$name"
  echo "$name" >> "$manifest"
done

# Plugin agents become Claude Code user agents (install.sh links them).
for f in "$plugin"/agents/*.md; do
  cp "$f" "$root/agents/"
  basename "$f" >> "$agents_manifest"
done
cp "$plugin"/agents/*.md "$root/skills/poteto-mode/references/agents/"

# Licenses and provenance travel with the import.
cp "$src/LICENSE" "$root/LICENSE-pstack"
cp "$src/LICENSE-cursor-team-kit" "$src/LICENSE-thermos" "$root/"
git -C "$src" rev-parse HEAD > "$root/skills/.pstack-commit" 2>/dev/null || true

# Keep the Claude Code, Codex, and Antigravity mappings. Drop the rest.
refs="$root/skills/poteto-mode/references"
for f in pi-tools copilot-tools muse-tools minimax-tools omp-tools kimi-tools grok dsh-tools opencode-tools; do
  rm -f "$refs/$f.md"
done
cp "$root/scripts/t3-tools.md" "$root/scripts/tstack-skills.md" "$refs/"

# setup-pstack's notes for the dropped harnesses point at those mappings.
setup_src="$root/skills/setup-pstack"
rm -f "$setup_src/copilot.md"
perl -0pi -e '
  my $gone = qr/Pi|GitHub Copilot|Muse|MiniMax Code|Kimi Code CLI|OMP|Grok Build|OpenCode 2|DeepSeek Harness/;
  s/^\| (?:$gone)[^|\n]*\|[^\n]*\n//mg;
  s/^## (?:$gone)\n.*?(?=^## |\z)//msg;
' "$setup_src/references/runtimes.md"
perl -0pi -e '
  s/# The default sheet is GitHub Copilot.s, so setup-pstack can run this without\n# naming a path outside the workspace\.\n/# The default sheet is the Claude Code user sheet.\n/ or die "check-sheet: comment anchor missing\n";
  s/\$\{COPILOT_HOME:-\$HOME\/\.copilot\}\/pstack-models\.md/\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/pstack-models.md/ or die "check-sheet: default path anchor missing\n";
' "$setup_src/scripts/check-sheet.sh"

find "$root/skills" "$root/agents" -name '*.md' | while IFS= read -r f; do
  grep -q 'pstack\|poteto\|platform mapping\|babysit\|plugin' "$f" || continue
  perl -0pi -e '
    # Per-skill preambles: drop other harnesses, add T3 Code after Codex.
    s/^On (?:GitHub Copilot|Muse|Pi|MiniMax Code|OMP|Kimi Code CLI|Grok Build|DeepSeek Harness|OpenCode 2), read the \[platform mapping\][^\n]*\n\n//mg;
    s/^(On Codex, read the \[platform mapping\]\(([^)]*)codex-tools\.md\)[^\n]*\n)/$1\nIn T3 Code, also read the [T3 Code mapping]($2t3-tools.md) before following this skill.\n/mg;
    # poteto-mode Platform Adaptation: Claude Code, Codex, Antigravity, T3 Code.
    s/ On Pi, read \[`references\/pi-tools\.md`\].*? On OpenCode 2, read \[`references\/opencode-tools\.md`\]\(references\/opencode-tools\.md\) instead\./ On Antigravity, read [`references\/agy-tools.md`](references\/agy-tools.md) instead. In T3 Code, on any provider, also read [`references\/t3-tools.md`](references\/t3-tools.md); it overrides the Claude Code, Codex, and Antigravity defaults where they differ./s;
    # Plugin agent types install as user agents, without the plugin prefix.
    s/pstack:(poteto-agent|comment-sicko|thermo-nuclear-review-subagent|thermo-nuclear-code-quality-review-subagent)/$1/g;
    s/(`[a-z-]+`) or \1/$1/g;
    s/ Plugin agents register under the plugin namespace\. The bare name `poteto-agent` errors\./ This install registers the agents without a plugin prefix, so use the bare name./g;
    # The standalone babysit skill is tstack babysit-pr.
    s/the bundled \*\*babysit\*\* skill/the **babysit-pr** skill/g;
    s/\(\.\.\/babysit\/SKILL\.md\)/(..\/babysit-pr\/SKILL.md)/g;
    s/pstack.s standalone \[`\/babysit`\]\(\.\.\/babysit-pr\/SKILL\.md\) skill/tstack\x27s [`babysit-pr`](..\/babysit-pr\/SKILL.md) skill/g;
    # Plugin paths become the skills directory install.sh links. Codex gets
    # the same links, so the Claude Code path resolves on both.
    s/<plugin>\/skills\//\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/skills\//g;
    s/`skills\/([^`]*)` under the installed plugin/`\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/skills\/$1`/g;
    s/under the installed plugin.s `skills\/([^`]*)` directory/in the `\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/skills\/$1` directory/g;
    s/ from disk under the installed plugin/ from disk/g;
    s/The local links point into the installed plugin/The local links point into the installed skills/g;
    # Installed skills are links into this checkout: edit them there.
    s/Never edit a skill under `plugins\/cache\/`\. Before approval, show its destination, .*?After approval, copy the skill folder there and edit the copy\./Never edit a skill under `plugins\/cache\/`. A skill that `readlink` shows is a link into the astack checkout is edited in that checkout, and the user commits it there. For any other skill, before approval, show its destination, `.claude\/skills\/<skill>\/` or `\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/skills\/<skill>\/`. After approval, copy the skill folder there and edit the copy./s;
    s/For a pstack skill, never edit the installed plugin under .*? and does not merge them\. \|/In this install, `\${CODEX_HOME:-~\/.codex}\/skills\/<skill>` is a link into the astack checkout, so edit a tstack skill in that checkout and let the user commit it. For any other skill, before approval show the destination, the repository\x27s `.agents\/skills\/<skill>\/` for a project copy, and after approval copy the skill folder there. |/s;
    # Links to the dropped harness mappings keep their text, lose the link.
    s/\[([^\]]*)\]\([^)]*\/(?:pi-tools|copilot-tools|muse-tools|minimax-tools|omp-tools|kimi-tools|grok|dsh-tools|opencode-tools)\.md(?:#[^)]*)?\)/$1/g;
  ' "$f"
done

# The poteto-agent definition looks for poteto-mode in the plugin cache.
perl -0pi -e 's/With no path, before any other work, search .*? If no such file exists, stop and tell your parent\./With no path, read `\${CLAUDE_CONFIG_DIR:-\$HOME\/.claude}\/skills\/poteto-mode\/SKILL.md`, or `\${CODEX_HOME:-\$HOME\/.codex}\/skills\/poteto-mode\/SKILL.md` on Codex, or `skills\/poteto-mode\/SKILL.md` inside the astack plugin folder on Antigravity. If none exists, stop and tell your parent./s' \
  "$root/agents/poteto-agent.md" "$refs/agents/poteto-agent.md"

# The router and its help page learn which tstack skill or playbook owns
# overlapping work, on every harness.
perl -0pi -e '
  s/(it overrides the Claude Code, Codex, and Antigravity defaults where they differ\.)/$1 This install also carries tstack\x27s skills (`full-send`, `full-stop`, `council`, `sol-loop`, `file-pr`, `takeover`, `modernize`, `babysit-pr`). Before a request that names one of them, or before opening a PR, read [`references\/tstack-skills.md`](references\/tstack-skills.md), which says whether the skill or a playbook owns the work./ or die "poteto-mode: Platform Adaptation anchor missing\n";
' "$root/skills/poteto-mode/SKILL.md"
perl -0pi -e '
  s/- "take over this branch" runs Session pickup\./- "pick up where I left off on this branch" runs Session pickup. "Take over" someone else\x27s PR, branch, or thread runs tstack\x27s [`takeover`](..\/takeover\/SKILL.md) skill instead./ or die "poteto-help: Session pickup anchor missing\n";
' "$root/skills/poteto-help/SKILL.md"

# Routing context for the SessionStart hook and AGENTS.md.
perl -pe 's/`pstack:([a-z-]+)`/`$1`/g; s/You have pstack\./You have astack: the tstack and pstack skills, with bunny-mode routing./; s/the right pstack skill/the right skill/' \
  "$plugin/hooks/session-start-context.md" > "$root/hooks/routing.md"
perl -pe 's/`pstack:([a-z-]+)`/`$1`/g; s/You have pstack\./You have astack: the tstack and pstack skills, with bunny-mode routing./; s/the right pstack skill/the right skill/' \
  "$plugin/hooks/session-start-agy.md" > "$root/hooks/routing-agy.md"
# Antigravity's hook prints JSON; upstream's POSIX awk helpers build it.
cp "$plugin/hooks/json.awk" "$plugin/hooks/agy-context.awk" "$root/hooks/"

# Rename the poteto-* entry points to bunny-*. Credit to poteto (Lauren Tan)
# stays in the router's description and in NOTICE.md.
mv "$root/skills/poteto-mode" "$root/skills/bunny-mode"
mv "$root/skills/poteto-help" "$root/skills/bunny-help"
mv "$root/agents/poteto-agent.md" "$root/agents/bunny-agent.md"
mv "$root/skills/bunny-mode/references/agents/poteto-agent.md" "$root/skills/bunny-mode/references/agents/bunny-agent.md"
grep -rlI --exclude-dir=node_modules 'poteto' "$root/skills" "$root/agents" "$root/hooks/routing.md" "$root/hooks/routing-agy.md" "$root/hooks/agy-context.awk" | while IFS= read -r f; do
  perl -pi -e '
    s/poteto-(mode|help|agent)/bunny-$1/g;
    s/^# Poteto (mode|help|subagent)$/# Bunny $1/;
    s/^description: poteto.s agent style/description: Bunny mode, an agent style adapted from poteto\x27s pstack,/;
    s/Use for poteto, \/bunny-mode/Use for bunny, \/bunny-mode/;
  ' "$f"
done
perl -pi -e 's/^poteto-(mode|help)$/bunny-$1/' "$manifest"
perl -pi -e 's/^poteto-agent\.md$/bunny-agent.md/' "$agents_manifest"

# The stack is astack: setup-pstack, its sheet, and its env switch take the
# astack name, and the setup skill also configures tstack's own roles.
mv "$root/skills/setup-pstack" "$root/skills/setup-astack"
grep -rlIE --exclude-dir=node_modules 'setup-pstack|pstack-models|PSTACK_SESSION_HOOK|Setup pstack|pstack model configuration|models pstack uses|configure pstack models' \
  "$root/skills" "$root/agents" "$root/hooks/routing.md" "$root/hooks/routing-agy.md" | while IFS= read -r f; do
  perl -pi -e '
    s/setup-pstack/setup-astack/g;
    s/pstack-models/astack-models/g;
    s/PSTACK_SESSION_HOOK/ASTACK_SESSION_HOOK/g;
    s/^# Setup pstack$/# Setup astack/;
    s/# pstack model configuration/# astack model configuration/;
    s/Configure which models pstack uses per role/Configure which models astack uses per role, for the pstack and tstack skills/;
    s/"configure pstack models"/"configure astack models"/;
  ' "$f"
done
perl -pi -e 's/^setup-pstack$/setup-astack/' "$manifest"

setup="$root/skills/setup-astack/SKILL.md"
perl -0pi -e '
  s/\n### 4\. Choose whether the session hook routes tasks\n/\n### 3b. Choose the tstack roles\n\nThree more lines set the models that tstack\x27s own skills use. Their values are T3 Code models, not `Agent` slugs. In T3 Code, resolve them with `orchestrator_capabilities` and offer what it lists, plus `claude flagship`, `gpt flagship`, and `gemini flagship`, which mean the newest flagship that provider lists when the skill runs. A concrete model ID, such as `gemini-4-neon`, pins that seat.\n\n- `council members`: the three council seats, one per provider. T3 Code\x27s default review panels use the same seats. Default `claude flagship, gpt flagship, gemini flagship`.\n- `sol-loop model`: the GPT model that sol-loop reviews with. Default `gpt flagship`.\n- `gemini providers`: the T3 Code providers to try, in order, for a Gemini seat. Default `antigravity, cursor, opencode`.\n\nOutside T3 Code these lines apply only when the harness can reach those providers.\n\n### 4. Choose whether the session hook routes tasks\n/ or die "setup-astack: step 4 anchor missing\n";
  s/(If a chosen real slug or level is not available, stop and ask again\.)/$1 Check the tstack lines from step 3b against `orchestrator_capabilities` instead. A model or provider it does not list needs a new choice./ or die "setup-astack: step 5 anchor missing\n";
  s/\n(default effort: session\nsession hook: on\n)/\ncouncil members: claude flagship, gpt flagship, gemini flagship\nsol-loop model: gpt flagship\ngemini providers: antigravity, cursor, opencode\n\n$1/ or die "setup-astack: sheet template anchor missing\n";
' "$setup"

# A rewrite above that stopped matching upstream leaves text this catches.
sh "$root/scripts/check.sh"

echo "imported $(wc -l < "$manifest" | tr -d ' ') pstack skills from $(cat "$root/skills/.pstack-commit" 2>/dev/null || echo "$src")"
