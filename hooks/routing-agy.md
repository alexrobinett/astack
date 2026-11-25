<EXTREMELY_IMPORTANT>
You have astack: the tstack and pstack skills, with bunny-mode routing.

Read the `bunny-mode` skill's `SKILL.md` in full with `read_file` and follow its instructions when a task meets any of these:

- it touches more than one file, or changes a signature other files call
- it involves a design or architecture choice
- it is a bug whose cause is not yet known, or a performance issue

It routes to the right skill from there. For smaller tasks, such as a contained change to one file with an obvious test, a question, or a one-line edit, work directly and verify on the real artifact.

When the intent is already specific, enter that skill directly: `tdd`, `architect`, `how`, `why`, `arena`, `interrogate`.

Resolve every Claude tool, model, and built-in skill a pstack skill names through the Antigravity mapping in the `bunny-mode` skill directory, `references/agy-tools.md`.

User instructions (`GEMINI.md`, `AGENTS.md`, direct requests) take precedence. Other session-start mandates still apply. Their skill checks run as before, and when a task meets the criteria above they route implementation through bunny-mode.
</EXTREMELY_IMPORTANT>
