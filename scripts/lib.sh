#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -W 2>/dev/null || pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -W 2>/dev/null || pwd)"
CODEX_ROOT="$PROJECT_ROOT/codex"
WORK_ROOT="$PROJECT_ROOT/.work"
DIST_ROOT="$PROJECT_ROOT/dist"
TARGET_ROOT="$PROJECT_ROOT/target"
PATCH_SERIES="$PROJECT_ROOT/patches/series"
WINDOWS_TARGET="x86_64-pc-windows-msvc"
SOURCE_LAYOUT_VERSION="2"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command is not available: $1"
}

native_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s\n' "$1"
  fi
}

codex_git() {
  git -c "safe.directory=$(native_path "$CODEX_ROOT")" -C "$CODEX_ROOT" "$@"
}

codex_commit() {
  codex_git rev-parse HEAD
}

patch_digest() {
  local patch_path
  local patch_hash
  local material=''

  [[ -f "$PATCH_SERIES" ]] || die "patch series is missing: $PATCH_SERIES"
  while IFS= read -r patch_path || [[ -n "$patch_path" ]]; do
    [[ -z "$patch_path" || "$patch_path" == \#* ]] && continue
    [[ -f "$PROJECT_ROOT/$patch_path" ]] || die "patch listed in series is missing: $patch_path"
    patch_hash="$(git -C "$PROJECT_ROOT" hash-object "$patch_path")"
    material+="$patch_path $patch_hash"$'\n'
  done < "$PATCH_SERIES"

  printf '%s' "$material" | git hash-object --stdin
}

build_key() {
  local commit
  local patches
  commit="$(codex_commit)"
  patches="$(patch_digest)"
  printf '%s-%s-v%s\n' "${commit:0:12}" "${patches:0:12}" "$SOURCE_LAYOUT_VERSION"
}

codex_version() {
  local source_root="${1:-$CODEX_ROOT}"
  python -c 'import pathlib, sys, tomllib; print(tomllib.loads((pathlib.Path(sys.argv[1]) / "codex-rs" / "Cargo.toml").read_text(encoding="utf-8"))["workspace"]["package"]["version"])' "$source_root"
}

codex_rust_toolchain() {
  python -c 'import pathlib, sys, tomllib; print(tomllib.loads((pathlib.Path(sys.argv[1]) / "codex-rs" / "rust-toolchain.toml").read_text(encoding="utf-8"))["toolchain"]["channel"])' "$CODEX_ROOT"
}

activate_codex_rust_toolchain() {
  local channel
  require_command rustup
  channel="$(codex_rust_toolchain)"
  rustup run "$channel" cargo --version >/dev/null 2>&1 || die "Codex requires Rust $channel; install it with: rustup toolchain install $channel --profile minimal"
  export RUSTUP_TOOLCHAIN="$channel"
}

latest_tarball_file() {
  printf '%s\n' "$WORK_ROOT/latest-package.txt"
}
