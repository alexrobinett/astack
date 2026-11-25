# tstack (+ code quality)

A fork of [t3dotgg/tstack](https://github.com/t3dotgg/tstack) with code-quality
skills adapted from [pstack](https://github.com/michael-denyer/pstack-claude).
See [Code quality](#code-quality) below.

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

## Code quality

Adapted from pstack (Lauren Tan, Cursor, and the
[pstack-claude](https://github.com/michael-denyer/pstack-claude) port). The
plugin agents became prompt files in each skill's `reviewers/` folder, so they
work as plain skills. Reviewers run as native subagents, or as `delegate_task`
children in T3 Code when you name a model on another provider.

| Skill | Say | What it does |
|---|---|---|
| `architect` | "architect this" | Sketches types, signatures, and module structure before code. |
| `thermos` | "thermos" | Runs both thermo-nuclear reviews in parallel and merges the findings. |
| `thermo-nuclear-review` | "thermo nuclear" | Strict audit of a diff for bugs, breaking changes, and security. |
| `thermo-nuclear-code-quality-review` | "code quality review" | Strict maintainability audit: abstractions, giant files, spaghetti. |
| `deslop` | "deslop" | Removes AI-generated slop from the branch's diff. |
| `no-comments` | "no comments" | Deletes needless comments and flags the code that needed them. |
| `blast-radius` | "blast radius" | Finds what a change could break beyond the diff, and proves it is safe. |
| `correct` | "correct" | Makes repeated agent mistakes impossible with types, lints, or tests. |
| `tdd` | "TDD" | Red-green-refactor when a cheap test target exists. |
| `typescript-best-practices` | (automatic) | TypeScript rules for any `.ts` or `.tsx` edit. |
| `principle-*` | (automatic in Claude Code; by name in Codex) | Eleven principles the agent applies while it designs, writes, tests, and debugs code. |

- `thermos` uses `thermo-nuclear-review` and `thermo-nuclear-code-quality-review`.
- `no-comments` uses `architect` and two principles.
- `architect` and `blast-radius` use `council` for large changes.

## Install

```bash
git clone https://github.com/alexrobinett/tstack
cp -R tstack/skills/* ~/.claude/skills/   # Claude Code
cp -R tstack/skills/* ~/.codex/skills/    # Codex
```

## Requirements

- An authenticated [GitHub CLI](https://cli.github.com) (`gh`).
- `python3` for `babysit-pr`'s `pr-wait` script.
- `council` and `sol-loop` need subagents on other providers' models. T3 Code
  does this with `delegate_task`. Otherwise you need a harness that can run
  those models.

## Make them yours

These are starting points. Edit them. Put personal settings, like which models
sit on your council, in your `CLAUDE.md` or `AGENTS.md`, so you can update the
skills without losing them.

## License

[MIT](LICENSE). The code-quality skills keep their upstream MIT licenses:
see [NOTICE.md](NOTICE.md).
