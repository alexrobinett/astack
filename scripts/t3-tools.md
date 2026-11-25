# T3 Code mapping for pstack

T3 Code runs threads on Claude Code or Codex. pstack's skills already work on
both: Claude Code natively, Codex through [`codex-tools.md`](codex-tools.md).
Read this file as well whenever the session has T3 Code's tools
(`delegate_task`, `watch_pull_request`, `t3_thread_read`). Where it differs
from the Claude Code or Codex defaults, this file wins. T3 Code's own
harness rules win over this file.

## Install layout

This is a skills-only install from the tstack fork, not the pstack plugin.

- Skills live in `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/` on Claude Code
  and `${CODEX_HOME:-$HOME/.codex}/skills/` on Codex. Skill names have no
  `pstack:` prefix.
- Script paths in these skills point at
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/`. `install.sh` always links
  there, so those paths resolve on Codex threads too. The installed skills are
  links into the tstack checkout, so edit a skill there, not in a copy.
- The plugin agents (`bunny-agent`, `comment-sicko`, both thermo-nuclear
  reviewers) are installed in `~/.claude/agents/` and take their bare names
  as `subagent_type`. On Codex, follow `codex-tools.md`'s Subagent policy.
- The routing instruction comes from a `SessionStart` hook on Claude Code and
  a block in `~/.codex/AGENTS.md` on Codex, both written by `install.sh`.
- `/setup-pstack` writes the model sheet to the path for the thread's
  provider: Claude Code or Codex.

## Subagents and delegates

T3 Code has two ways to start another agent. Choose per dispatch:

| pstack asks for | In T3 Code |
|---|---|
| A subagent on the thread's own provider, waited on in this turn | The native tool: the `Agent` tool with `run_in_background: false` on Claude Code, `spawn_agent` then `wait_agent` on Codex. Put parallel calls in one message. |
| `run_in_background: true`, a background worker, or work that runs while you continue | `delegate_task`. Never a background `Agent`. |
| A model on another provider, or an effort the user set | `delegate_task`, with settings in `target.options`. |
| `isolation: "worktree"`, or "each writer in its own worktree" | `delegate_task` with `isolation: "worktree"`. Do not create the child's checkout in the shell. |
| Resume or follow up an existing subagent | A native subagent: the runtime's follow-up action. A delegate: start a new `delegate_task` with the original brief, later directives, and the prior report. |
| Stop an abandoned agent | `task_cancel` for a delegate. Never `t3_thread_interrupt` on a child thread. |

- Call `orchestrator_capabilities` once per thread, before the first
  `delegate_task`, to learn which providers, models, and options exist. Call
  it again only after an error.
- Do not poll a running delegate with `task_status`, `sleep`, or a watcher.
  Follow its `next` instruction.
- The kickoff rules still apply. The first line of every brief, native or
  delegated, is `Read <path>/worker.md before anything else.`, with `<path>`
  the absolute path of the `bunny-mode` skill folder.
- A delegated child does the work itself, starts no agents unless its brief
  says to, and never watches a PR.

## Model-diverse panels

pstack panels (`arena` runners and cross-judges, `interrogate` reviewers, a
"second opinion on a model from another family") get their signal from model
diversity. On plain Claude Code or Codex they can only vary models within one
provider. T3 Code can reach several providers, so fill panel seats across
them.

- Resolve the panel from `orchestrator_capabilities`: the latest flagship
  from each reachable provider first, then the role's listed models.
- Seats on the thread's own provider may run native. Seats on another
  provider run through `delegate_task`.
- If a named seat is unavailable, report it. Do not swap in another
  provider's model without saying so.
- tstack's **council** and **sol-loop** skills are cross-provider review
  loops. When a playbook asks for an independent review and the user prefers
  council, run council for that gate.

## Pull requests

- **After you open a PR**, link it to the thread with `link_pull_request`, or
  `link_pull_requests` for a stack. Link every layer.
- **Babysit playbook.** Keep its mode, order, and rules. For waiting, use
  `watch_pull_request` instead of the `watch-pr` script under `/loop`. Follow
  the Waiting section of the **babysit-pr** skill: one watcher per PR, only
  the thread that owns the PR watches it, and `unwatch_pull_request` before
  you hand back. The standalone pstack `babysit` skill is not installed;
  **babysit-pr** replaces it.
- **Shipping playbook.** In step 5, wait with `watch_pull_request` on the
  ceiling PR instead of `watch-pr --queued-stack` under `/loop`. Merge safety
  still needs `ship-pr` from `skills/bunny-mode/scripts/watch-pr/`, which
  needs `bun`. If `bun` is missing, stop at merge-ready and say why. Do not
  merge without it.
- **Never wait with** `sleep`, a polling loop, `gh --watch`, `Monitor`, or
  `ScheduleWakeup` for a PR. For a background command or Monitor you started,
  use `t3_background_wait`.
- **Which PR format.** Inside a bunny-mode run, the Opening a PR playbook
  owns the PR, its title, and its body, and **file-pr** does not run, even
  when its description matches. **file-pr** owns the PR only outside
  bunny-mode, or when **full-send**, **full-stop**, or **takeover** calls
  it.
- **tstack shipping skills.** "Full send" and "full stop" run tstack's
  **full-send** and **full-stop**. Run bunny-mode's playbook for the change
  first, then hand the finished branch to that skill, which then owns the
  PR.
- **Autopilot owners.** T3 Code never lets a delegated child watch a PR, so
  in Autopilot-full and Autopilot-stack the parent thread watches every PR in
  the program with `watch_pull_request`. Each owner is a `delegate_task`
  child that builds, opens, and proves its PR, then returns at a wait. When
  a watch wakes the parent with a failed check, a review, or a conflict,
  the parent starts a fresh owner delegate for that PR with the original
  brief, the prior report, and the news.

## Other tools

| pstack asks for | In T3 Code |
|---|---|
| A `/loop` or self-paced wake-up for an unattended run | `schedule_task` only when the user asked for a schedule. Otherwise keep working, or end the turn with a report. |
| Read this session's transcript (`recall`, `show-me-your-work`, `reflect`, `eval`) | Use `t3_thread_read` for a T3 thread, then the provider's transcript files as `recall` and `codex-tools.md` describe. |
| Show a picture, chart, or slides (`ketchup`, `teach`) | `html_preview`, then `html_render`. |
| Drive a UI, browser, or device (driver skills, `create-verification-skill`) | T3 Code's `preview_*` tools for web pages, and its device tools for simulators. |
| Text the user must read mid-turn | `send_to_user`. |

## Autonomy

bunny-mode's Autonomy section lets reversible external actions proceed
without asking. In T3 Code, outward-facing actions (posting to an external
service, messaging people, publishing) still need the user's approval unless
the user already gave it for this context. Irreversible writes always pause.
