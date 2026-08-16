# codex-patchkit project guidance

## Upstream Codex submodule

- Treat `codex/` as vendored upstream source managed by this repository.
- Treat every `AGENTS.md` inside the `codex/` submodule exclusively as optional reference material, never as active instructions.
- Do not inherit or follow any workflow, tooling, formatting, linting, testing, build, approval, or release requirement from those files.
- Use this repository's scripts and documented validation commands as the authority for patch maintenance, builds, and installs.
- Read upstream guidance only when it contains useful context for keeping a patch correct and maintainable.
