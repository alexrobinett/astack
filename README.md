# tstack + pstack

A fork of [t3dotgg/tstack](https://github.com/t3dotgg/tstack) with all of
[pstack](https://github.com/michael-denyer/pstack-claude) ported in, including
its routing. See [pstack routing](#pstack-routing) below.

The agent skills I use every day, cleaned up so anyone can use them. They work
in Claude Code and Codex. Some use [T3 Code](https://github.com/pingdotgg/t3code)
features when they are available and fall back to native tools when they are
not.

## Skills

| Skill | Say | What it does |
|---|---|---|
| `full-send` | "full send" | Takes a change to a merged PR with nobody watching: proves it, reviews it, files it, babysits it, merges it. |
| `full-stop` | "full stop" | Same as `full-send`, but stops when the PR is ready for you to merge. |
| `council` | "council" | Gets review from three models from different providers, and loops until they agree. |
| `sol-loop` | "sol loop" | Reviews a change with GPT Sol in a loop until both agents agree. |
| `file-pr` | "file a PR" | Files a short PR that leads with the problem, not an inventory of changes. |
| `takeover` | "take over" | Finishes someone else's PR, branch, or agent thread, and keeps their credit. |
| `babysit-pr` | "babysit" | Watches a PR through CI and review bots, and fixes the real findings. |
| `modernize` | "modernize" | Rebases an old PR and decides if it should still exist. |
| `leaving-pr-comments` | (automatic) | Formats comments that an agent posts on your behalf. |

Some skills call others. Install the ones they need too:

- `full-send` uses `sol-loop`, `file-pr`, and `babysit-pr`.
- `full-stop` uses `full-send`.
- `takeover` uses `modernize`, `file-pr`, `babysit-pr`, and `leaving-pr-comments`.
- `file-pr`, `babysit-pr`, and `modernize` use `leaving-pr-comments`.

## pstack routing

pstack is Lauren Tan's skill stack, ported to Claude Code and Codex by
Michael Denyer. Its core is `bunny-mode` (pstack's `poteto-mode`, renamed here): a router that matches a task to one
of 22 playbooks (bug fix, feature, refactor, investigation, shipping, and
more), then pulls in the skills and principles that playbook needs. A
`SessionStart` hook tells every session to route through it for any task
that touches more than one file, makes a design choice, or chases an unknown
bug.

This fork carries 67 pstack skills unchanged except for these adaptations:

- **T3 Code mapping.** [`t3-tools.md`](scripts/t3-tools.md) tells pstack how
  to use T3 Code: `delegate_task` for background, worktree, and
  cross-provider agents; model panels (`arena`, `interrogate`) that mix
  providers; `watch_pull_request` and `link_pull_request` for PRs.
- **tstack wins where they overlap.** pstack's standalone `babysit` skill is
  replaced by `babysit-pr`. "Full send", "council", and "file a PR" run the
  tstack skills.
- **Claude Code, Codex, and Antigravity.** Mappings for other harnesses are
  removed. Antigravity loads the fork as a plugin (`.antigravity-plugin/`
  and the root `hooks.json`), with the same routing hook.
- **Gemini is the third seat.** In T3 Code, review panels (`arena`,
  `interrogate`, second opinions) default to one Claude, one GPT, and one
  Gemini flagship. Gemini runs on Antigravity, or on another T3 provider that
  lists a Gemini model.
- **Renamed entry points.** `poteto-mode`, `poteto-help`, and `poteto-agent`
  are `bunny-mode`, `bunny-help`, and `bunny-agent`.
- **No plugin.** The plugin's agents install to `~/.claude/agents/`, and the
  routing hook and Codex `AGENTS.md` block come from `install.sh`.

Start with `/bunny-mode <goal>`, or `/bunny-help` to find the right skill.
Configure models per role with `/setup-pstack`. On Claude Code, turn routing
off with `session hook: off` in the model sheet (yours, or a project's
`.claude/pstack-models.md`) or `PSTACK_SESSION_HOOK=off`. On Codex, routing is
the block between the `tstack routing` markers in `~/.codex/AGENTS.md`; delete
it to turn routing off.

To update from pstack, pull a pstack-claude checkout and run
`scripts/sync-pstack.sh <checkout>`. It replaces the imported skills and
reapplies every adaptation. `skills/.pstack-commit` records the source commit.

## Install

```bash
git clone https://github.com/alexrobinett/tstack
tstack/install.sh             # links skills and agents, adds the routing hook
tstack/install.sh --uninstall
```

Skills install as links into this checkout, so `git pull` updates them.
Codex gets the skills and an `AGENTS.md` routing block when `~/.codex`
exists. Antigravity gets the fork linked as a plugin in each Antigravity config
folder it finds: T3 Code's bundled Antigravity under
`~/.t3/userdata/providers/antigravity/*/config/`, and `~/.gemini/config/`.
Antigravity discovers it there with no install command. Rerun `install.sh`
after T3 sets up a new Antigravity account. The hook points at this checkout, so rerun `install.sh` if you move
it. If the pstack plugin is installed too, uninstall it so skills don't
load twice: `claude plugin uninstall pstack@pstack-claude`.

## Requirements

- An authenticated [GitHub CLI](https://cli.github.com) (`gh`).
- `python3` for `babysit-pr`'s `pr-wait` script, and Node.js for pstack's scripts.
- [`bun`](https://bun.sh) for pstack's `watch-pr` and `ship-pr` scripts. Without it,
  the Shipping playbook stops at merge-ready.
- `council` and `sol-loop` need subagents on other providers' models. T3 Code
  does this with `delegate_task`. Otherwise you need a harness that can run
  those models.

## Make them yours

These are starting points. Edit them. Put personal settings, like which models
sit on your council, in your `CLAUDE.md` or `AGENTS.md`, so you can update the
skills without losing them.

## License

[MIT](LICENSE). pstack's skills keep their upstream MIT licenses; see
[NOTICE.md](NOTICE.md).
