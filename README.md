# codex-patchkit

This repository pins OpenAI Codex as a Git submodule, applies a small ordered patch series to a clean source export, builds the Windows release package, and installs it through pnpm.

The clean `codex/` submodule is never patched in place. Generated patched source, Cargo state, build output, and package staging live under ignored project directories.

## current release

- Codex: `rust-v0.147.0`
- Active patch: `dwm-perf/shared-private-desktop.patch`
- Target: `x86_64-pc-windows-msvc`

The former ACL performance patches are not part of this project. Codex `0.147.0` contains the upstream ACL convergence fix, so this repository does not add stronger local ACL semantics.

The root PowerShell files are retained only as ignored local reference material. They are not build inputs and are not committed.

## patch provenance

The shared-private-desktop fix is adapted from [codengine's `codex-0.144.5-shared-private-desktop.patch`](https://github.com/openai/codex/issues/33192#issuecomment-5017820258), shared in [OpenAI Codex issue #33192](https://github.com/openai/codex/issues/33192). The original patch introduced one private desktop per Codex process and was tested across thousands of tool calls without DWM memory or CPU growth.

This repository rebases that design onto Codex `rust-v0.147.0`. The rebase preserves intervening upstream IPC, console-mode, job-object, logging, and network-restriction behavior. See `dwm-perf/README.md` for the exact compatibility changes and maintenance boundary.

## setup and build

Initialize the submodule after cloning:

````bash
git submodule update --init
````

Fetch the locked Windows Cargo dependencies and checksum-verified OpenAI V8 artifacts:

````bash
pnpm deps:fetch
````

The script reads the required Rust version from `codex/codex-rs/rust-toolchain.toml` and refuses to continue when that rustup toolchain is absent. Install the named toolchain first when a version bump changes it.

The release manifest uses the release version while the upstream lockfile can still contain `0.0.0` for workspace path packages. The seed runs against the ignored generated source and permits only those workspace-version lockfile replacements. It rejects every registry version, checksum, source, dependency, or line-count change.

This is the only networked build step. It writes only to ignored `.work/source/`, `.work/cargo/`, `.work/v8/`, and Cargo's project target directory. Run it once for the pinned Codex version and again after a version bump changes dependencies.

Check the patch stack without compiling:

````bash
pnpm patches:check
````

Build and package Codex with Cargo forced offline:

````bash
pnpm build
````

The build uses the upstream canonical package builder. The resulting local npm package embeds its Windows payload under `vendor/x86_64-pc-windows-msvc` and is written to `dist/`.

Install or reinstall the most recently built package through pnpm:

````bash
pnpm install:built
````

This runs `pnpm add --global --force` on the local tarball. It does not scan or modify pnpm's content-addressed store directly.

## version bumps

Fetch and pin a release tag, then check whether the patch still applies:

````bash
pnpm codex:update -- 0.148.0
````

If the patch check fails, rebase the patch against the new submodule commit before building. Keep each independent behavior in its own patch folder and list active patches in `patches/series` in application order.

After a successful version bump:

1. Review the `codex` submodule gitlink change.
2. Update the documented current release.
3. Rebase and document patches that no longer apply.
4. Run `pnpm deps:fetch` in a network-enabled user session.
5. Run `pnpm patches:check` and `pnpm build`.
6. Install with `pnpm install:built`.

## generated state

- `.work/source/`: clean Codex archives with the ordered patch stack applied
- `.work/cargo/`: project-owned Cargo home
- `.work/v8/`: checksum-verified V8 build artifacts
- `.work/build/`: canonical Codex package directories
- `.work/npm-stage/`: temporary npm package staging
- `target/`: Rust build output keyed by Codex commit and patch digest
- `dist/`: installable local npm tarballs

All generated paths are ignored. The source of truth is the pinned `codex/` gitlink plus the patch files listed in `patches/series`.

## license

This project is licensed under the Apache License 2.0. See `LICENSE` and `NOTICE`. The `codex/` submodule retains its upstream license and notices.
