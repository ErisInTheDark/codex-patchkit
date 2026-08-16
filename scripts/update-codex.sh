#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command git
[[ -z "$(codex_git status --porcelain)" ]] || die "codex/ has local changes; preserve or discard them before changing versions"

requested="${1:-}"
[[ -n "$requested" ]] || die "usage: pnpm codex:update -- <version-or-rust-tag>"
if [[ "$requested" == rust-v* ]]; then
  tag="$requested"
else
  tag="rust-v$requested"
fi

printf 'fetching Codex tag %s\n' "$tag"
codex_git fetch origin "refs/tags/$tag:refs/tags/$tag"
codex_git checkout --detach "$tag"

printf 'checking the active patch series against %s\n' "$tag"
bash "$SCRIPT_DIR/prepare-source.sh" --check

cat <<EOF
Codex is pinned to $tag and the active patch series applies cleanly.
Review the parent repository's codex gitlink change, then run pnpm deps:fetch.
EOF
