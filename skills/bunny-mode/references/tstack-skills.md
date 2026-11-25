# tstack skills in a bunny-mode run

astack installs tstack's skills beside pstack's: **full-send**, **full-stop**,
**council**, **sol-loop**, **file-pr**, **takeover**, **modernize**,
**babysit-pr**, and **leaving-pr-comments**. Some of them cover the same work
as a bunny-mode playbook. This file says which one owns the work. It applies
on every harness.

| The user says | What runs |
|---|---|
| "full send", "full stop" | Run bunny-mode's playbook for the change first. Then hand the finished branch to **full-send** or **full-stop**, which owns the PR from there. |
| "council" | **council**. When a playbook asks for an independent review and the user prefers council, run council for that gate. |
| "sol loop" | **sol-loop**. |
| "file a PR", outside a bunny-mode run | **file-pr**. |
| A PR opened at the end of a bunny-mode playbook | The Opening a PR playbook owns the PR, its title, and its body. **file-pr** does not run, even when its description matches. |
| "take over" someone else's PR, branch, or agent thread | **takeover**. |
| Resume your own earlier chat or branch | The Session pickup playbook. |
| "modernize", or rebase an old PR | **modernize**. |
| "babysit", or PR status | The Babysit playbook. Its waiting follows the Waiting section of **babysit-pr**. pstack's standalone `babysit` skill is not installed. |

**file-pr** also owns the PR whenever **full-send**, **full-stop**, or
**takeover** calls it. Every comment an agent posts on a PR follows
**leaving-pr-comments**.

**council** and **sol-loop** need models from other providers. A harness that
cannot reach them reports the missing seat. It does not substitute a model
from its own provider without saying so.
