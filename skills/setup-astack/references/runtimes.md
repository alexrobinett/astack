# Other runtimes

The role lines are the same everywhere. What differs is the sheet path, how the runtime loads it, and how you list models. Detect models with the runtime's own tool and never write a slug you have not seen listed. A runtime whose subagent call has no model parameter still gets the sheet, as the record of the user's choice, and applies it where it can. The `session hook` line applies to the Claude Code, Codex, GitHub Copilot, Muse, MiniMax Code, Antigravity, OMP, and OpenCode 2 plugins and to the pstack Pi extension.

`<codex-home>` is `$CODEX_HOME` when that variable is set and `~/.codex` otherwise.

| Runtime | Sheet | Load | List models | Status |
| --- | --- | --- | --- | --- |
| Claude Code | `<config>/astack-models.md`, or `.claude/astack-models.md` at the repository root, which replaces it in that project | `@<config>/astack-models.md` in `<config>/CLAUDE.md`, or `@.claude/astack-models.md` in the repository root's `CLAUDE.md` | the `Agent` tool's model parameter | verified live |
| Codex | `<codex-home>/astack-models.md` | model rows: paste into `<codex-home>/AGENTS.md`; hook setting: read by the plugin | your configured Codex models, see [codex-tools.md](../../bunny-mode/references/codex-tools.md#model-names) | hook contract tested; discovery verified |
| Antigravity (`agy`) | `~/.gemini/config/astack-models.md` | model rows: read by the agent before a role-model skill, or paste into `~/.gemini/config/AGENTS.md`; hook setting: read by the plugin's `SessionStart` hook | `invoke_subagent`'s `Model` enum (`inherit`, `flash_lite`, `flash`, `pro`), see [agy-tools.md](../../bunny-mode/references/agy-tools.md#model-names) | tested with `agy` 1.5.0 on macOS: plugin install, hook on/off, full skill read and a live subagent reply; Windows untested |
| Gemini CLI | `~/.gemini/astack-models.md` | `@~/.gemini/astack-models.md` in `~/.gemini/GEMINI.md` | the `model` slash command in the session | from published docs, no live session |
| Prime Agent | no documented sheet path; Prime's configuration chooses models | | | no live session |

Every runtime uses its row above in place of the Claude Code paths and step 7's include line. A section below exists only for a step change the table cannot express.

## Codex

- **Step 3 (map and confirm).** `session` effort requires the current thread's active-turn metadata, which some hosts do not expose. The platform mapping's helper reads it; when it is unavailable, an explicit effort choice is required before dispatching. Offer a fixed default level for those hosts instead of promising automatic inheritance.
- **Step 4 (session hook).** The plugin's `SessionStart` hook injects the mandate as on Claude Code, after the user trusts plugin hooks through `/hooks`.
- **Step 5 (validate).** The effort levels are the `reasoning_effort` values your Codex models accept.
- **Step 7 (wire it in).** Paste the `default effort` line into `<codex-home>/AGENTS.md` with the model rows, but not the `session hook` line: the plugin hook reads that from the sheet.

## Antigravity

- **Steps 3 and 5 (effort, validate).** `invoke_subagent` takes a `Model` and no effort parameter. Skip the effort questions in step 3 and effort validation in step 5, and omit the `default effort` line and `@<level>` suffixes.

