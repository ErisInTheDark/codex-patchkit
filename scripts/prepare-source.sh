#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command git
require_command tar

[[ -d "$CODEX_ROOT" ]] || die "initialize the codex/ submodule first"
[[ -f "$CODEX_ROOT/codex-rs/Cargo.toml" ]] || die "codex/ does not contain a Codex source checkout"
[[ -z "$(codex_git status --porcelain)" ]] || die "codex/ has local changes; preserve or discard them before preparing a build"

commit="$(codex_commit)"
patches="$(patch_digest)"
key="${commit:0:12}-${patches:0:12}-v${SOURCE_LAYOUT_VERSION}"
source_root="$WORK_ROOT/source/$key"
source_relative=".work/source/$key"
marker="$source_root/.codex-patchkit-source"
legacy_marker="$source_root/.codex-perf-source"
expected_marker="layout=$SOURCE_LAYOUT_VERSION codex=$commit patches=$patches"

if [[ ! -f "$marker" && -f "$legacy_marker" ]]; then
  mv "$legacy_marker" "$marker"
fi

if [[ -f "$marker" ]]; then
  [[ "$(cat "$marker")" == "$expected_marker" ]] || die "generated source marker does not match: $source_root"
else
  if [[ -d "$source_root" && -n "$(ls -A "$source_root" 2>/dev/null)" ]]; then
    die "generated source directory is incomplete; remove it before retrying: $source_root"
  fi

  mkdir -p "$source_root"
  printf 'exporting Codex %s to %s\n' "${commit:0:12}" "$source_root" >&2
  codex_git archive --format=tar "$commit" | tar -xf - -C "$source_root"

  while IFS= read -r patch_path || [[ -n "$patch_path" ]]; do
    [[ -z "$patch_path" || "$patch_path" == \#* ]] && continue
    printf 'applying %s\n' "$patch_path" >&2
    git -C "$PROJECT_ROOT" apply --check --directory="$source_relative" "$PROJECT_ROOT/$patch_path"
    git -C "$PROJECT_ROOT" apply --directory="$source_relative" "$PROJECT_ROOT/$patch_path"
  done < "$PATCH_SERIES"

  printf '%s\n' "$expected_marker" > "$marker"
fi

if [[ "${1:-}" == "--check" ]]; then
  printf 'patch series applies cleanly to Codex %s\n' "${commit:0:12}"
else
  printf '%s\n' "$source_root"
fi
