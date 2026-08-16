# codex-patchkit ♡

wave a tiny patch kit wand for building a pinned Codex release on Windows without poking the upstream source checkout (｡•̀ᴗ-)✧

## what's alive nyow

- Codex `rust-v0.147.0`
- target `x86_64-pc-windows-msvc`
- active patch `dwm-perf/shared-private-desktop.patch`
- package manager pnpm

`codex/` stays clean. the scripts export it into ignored project state, apply `patches/series`, build offline, and pack a normal installable `@openai/codex` tarball.

## the DWM fix

every sandboxed tool call used to create its own Windows private desktop, which made DWM progressively sad and crunchy. the patch gives each Codex process one shared private desktop instead.

the original design and implementation came from [codengine's `codex-0.144.5-shared-private-desktop.patch`](https://github.com/openai/codex/issues/33192#issuecomment-5017820258). this repo rebases it onto Codex `0.147.0` while preserving newer IPC, network-restriction, console-mode, logging, and job-object behavior.

the exact rebase notes live in [`dwm-perf/README.md`](dwm-perf/README.md). credit where credit is due, nyaaaa!!!! (✧▽✧)

## build the beastie

````bash
git submodule update --init
pnpm deps:fetch
pnpm patches:check
pnpm build
pnpm install:built
````

`pnpm deps:fetch` is the only networked build step. it seeds repo-owned Cargo and V8 caches. `pnpm build` then uses those caches offline and writes the installable package to `dist/`.

## bump Codex

````bash
pnpm codex:update -- 0.148.0
````

if the patch no longer applies, rebase it against the new submodule commit. then seed, check, build, and install again. no mystery migration ceremony, yayyy (˶ᵔ ᵕ ᵔ˶)

## license

Apache 2.0. see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
