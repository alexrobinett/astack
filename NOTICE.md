# Notice

This fork of [t3dotgg/tstack](https://github.com/t3dotgg/tstack) (MIT, (c) 2026
Theo Browne, see [LICENSE](LICENSE)) adds code-quality skills adapted from
[michael-denyer/pstack-claude](https://github.com/michael-denyer/pstack-claude)
at commit `2f6de89`.

| Included work | Upstream | Copyright | License |
| --- | --- | --- | --- |
| `architect`, `blast-radius`, `correct`, `no-comments` (with the `comment-sicko` reviewer), `tdd`, `typescript-best-practices`, and the `principle-*` skills | [cursor/plugins/pstack](https://github.com/cursor/plugins/tree/main/pstack) | (c) 2026 Lauren Tan | [MIT](LICENSE-pstack) |
| `deslop` | [cursor/plugins/cursor-team-kit](https://github.com/cursor/plugins/tree/main/cursor-team-kit) | (c) 2026 Cursor | [MIT](LICENSE-cursor-team-kit) |
| `thermos`, `thermo-nuclear-review`, `thermo-nuclear-code-quality-review`, and their reviewer prompts | [cursor/plugins/thermos](https://github.com/cursor/plugins/tree/main/thermos) | (c) 2026 Cursor | [MIT](LICENSE-thermos) |

The pstack-claude port's changes are (c) 2026 Michael Denyer under the same MIT
license ([LICENSE-pstack](LICENSE-pstack)). This fork removed the per-harness
platform notes and the pstack model sheet, turned the plugin agents into
`reviewers/*.md` prompt files, and pointed `arena` and `why` references at
`council` and git history.
