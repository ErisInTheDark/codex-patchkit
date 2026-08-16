#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command pnpm

latest_file="$(latest_tarball_file)"
[[ -f "$latest_file" ]] || die "no built package is recorded; run pnpm build first"
tarball="$(cat "$latest_file")"
[[ -f "$tarball" ]] || die "recorded package does not exist: $tarball"

pnpm add --global --force "$tarball"
require_command codex
codex --version
