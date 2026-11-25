---
name: thermos
description: "Launch both thermo-nuclear reviewers in parallel, then synthesize their findings. Use for thermos, double thermo review, or combined bug/security and code-quality branch audits."
---

# Thermos

Run the two thermo review passes as parallel, read-only reviewers, then
synthesize their results.

## Workflow

1. Determine the review scope from the user request, PR, current branch, or
   relevant changed files. The default base is the PR's base branch, else
   `main`.
2. Gather the diff (`git diff <base>...HEAD` plus uncommitted changes) and the
   full contents of the changed files. Hand bulk reading to a subagent when
   the set is large.
3. Start both reviewers in parallel. Each one's prompt is the matching file in
   [`reviewers/`](reviewers/), followed by `### Git / diff output` and
   `### Changed file contents` sections:
   - [`reviewers/thermo-nuclear-review.md`](reviewers/thermo-nuclear-review.md)
     for bugs, breakages, security, devex regressions, feature-flag leaks, and
     other branch-audit risks.
   - [`reviewers/thermo-nuclear-code-quality-review.md`](reviewers/thermo-nuclear-code-quality-review.md)
     for maintainability, structure, file-size growth, spaghetti,
     abstractions, and codebase-health risks.

   In Claude Code, use the `Agent` tool, both calls in the same message. In
   Codex, use `spawn_agent` for each, then wait. In T3 Code, use those native
   tools for same-provider reviewers. If the user's instructions name a
   reviewer model on another provider, use `orchestrator_capabilities` to
   resolve it and `delegate_task` to start it. Use a strong model at high
   reasoning effort. Keep both reviewers read-only.
4. After both finish, synthesize the results with findings first,
   deduplicated across reviewers. Weight overlapping findings more heavily,
   resolve disagreements with your own judgment, and keep summaries brief.

If individual reviewer summaries are already visible to the user, do not
restate them wholesale. Surface the unified verdict, the highest-signal
findings, and any remaining uncertainty.
