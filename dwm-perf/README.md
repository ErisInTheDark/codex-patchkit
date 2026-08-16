# shared private desktop patch

`shared-private-desktop.patch` rebases the Windows private-desktop performance fix onto Codex `rust-v0.147.0`.

## provenance

The original design and implementation are from [codengine's attached `codex-0.144.5-shared-private-desktop.patch`](https://github.com/openai/codex/issues/33192#issuecomment-5017820258) in [OpenAI Codex issue #33192](https://github.com/openai/codex/issues/33192). That patch targets Codex `0.144.5`, creates one private desktop per Codex process, and was reported stable across thousands of tool calls without DWM memory or CPU growth.

The patch in this folder is a compatibility rebase, not an original replacement implementation. Relative to the attached `0.144.5` patch, it:

- updates patch context for Codex `0.147.0`;
- bumps the elevated-runner IPC protocol from `5` to `6` instead of the original `4` to `5`;
- preserves the newer network-proxy restricting SID field and its test coverage; and
- preserves newer `ConsoleMode`, job-object ownership, logging, and process-spawn behavior.

The shared-desktop design and original implementation remain credited to codengine.

## behavior

- A process-global owner lazily creates one shared private desktop instead of creating and destroying a desktop for every sandboxed process.
- Legacy and ConPTY launches target that shared desktop.
- Elevated launches receive the parent-owned desktop name through the framed IPC request.
- The parent grants the elevated account SID access to the named desktop.
- The IPC protocol version is `6`, preserving the existing version `5` network-restriction field while adding `private_desktop_name`.
- Existing `ConsoleMode`, job-object ownership, and network proxy restrictions remain intact.

The process-global owner is the single lifecycle owner. Callers select `Default`, `SharedPrivate`, or `NamedPrivate`; they do not create parallel desktop caches or mirror ownership state.

## maintenance

The patch must apply to a clean archive of the pinned `codex/` commit. Run:

````bash
pnpm patches:check
````

After a Codex version bump, rebase this patch when Windows sandbox process creation, elevated IPC, desktop ACLs, or command-runner protocol fields change.
