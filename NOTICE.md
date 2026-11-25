# Notice

astack, this fork of [t3dotgg/tstack](https://github.com/t3dotgg/tstack) (MIT, (c) 2026
Theo Browne, see [LICENSE](LICENSE)) imports every skill and agent from
[michael-denyer/pstack-claude](https://github.com/michael-denyer/pstack-claude)
except `babysit`, at the commit recorded in `skills/.pstack-commit`. The list of
imported skills is `skills/.pstack-skills`.

| Included work | Upstream | Copyright | License |
| --- | --- | --- | --- |
| pstack skills, principles, playbooks, scripts, and agents | [cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack) | (c) 2026 Lauren Tan | [MIT](LICENSE-pstack) |
| `deslop`, `make-pr-easy-to-review`, `fix-ci`, `fix-merge-conflicts`, `get-pr-comments`, `what-did-i-get-done` | [cursor/plugins/cursor-team-kit](https://github.com/cursor/plugins/tree/main/cursor-team-kit) | (c) 2026 Cursor | [MIT](LICENSE-cursor-team-kit) |
| `thermos`, `thermo-nuclear-review`, `thermo-nuclear-code-quality-review`, and their agents | [cursor/plugins/thermos](https://github.com/cursor/plugins/tree/main/thermos) | (c) 2026 Cursor | [MIT](LICENSE-thermos) |

The pstack-claude port's changes are (c) 2026 Michael Denyer under the same MIT
license ([LICENSE-pstack](LICENSE-pstack)). `scripts/sync-pstack.sh` records
every change this fork makes to the imported files, and
`scripts/t3-tools.md` is this fork's own addition. pstack's `poteto-mode`,
`poteto-help`, and `poteto-agent` are renamed `bunny-mode`, `bunny-help`, and
`bunny-agent`, and `setup-pstack` is renamed `setup-astack`; the router's
description still credits poteto.
