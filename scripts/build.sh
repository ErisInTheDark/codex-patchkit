#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command cargo
require_command git
require_command pnpm
require_command python
require_command rg
require_command tar
activate_codex_rust_toolchain

CARGO_HOME_DIR="$WORK_ROOT/cargo"
V8_CACHE_DIR="$WORK_ROOT/v8"
[[ -f "$CARGO_HOME_DIR/config.toml" ]] || die "dependency seed is missing; run pnpm deps:fetch first"

source_root="$(bash "$SCRIPT_DIR/prepare-source.sh")"
key="$(build_key)"
package_root="$WORK_ROOT/build/$key/codex-package"
mkdir -p "$(dirname "$package_root")" "$TARGET_ROOT/$key"

export CARGO_HOME="$(native_path "$CARGO_HOME_DIR")"
export CARGO_TARGET_DIR="$(native_path "$TARGET_ROOT/$key")"
export CARGO_NET_OFFLINE=true
export PYTHONPATH="$source_root/scripts"

v8_version="$(python -c 'from codex_package.v8 import resolved_v8_crate_version; print(resolved_v8_crate_version())')"
v8_dir="$V8_CACHE_DIR/rusty-v8-$v8_version-$WINDOWS_TARGET"
export RUSTY_V8_ARCHIVE="$(native_path "$v8_dir/rusty_v8_ptrcomp_sandbox_release_${WINDOWS_TARGET}.lib.gz")"
export RUSTY_V8_SRC_BINDING_PATH="$(native_path "$v8_dir/src_binding_ptrcomp_sandbox_release_${WINDOWS_TARGET}.rs")"
[[ -f "$RUSTY_V8_ARCHIVE" ]] || die "V8 archive is missing; run pnpm deps:fetch"
[[ -f "$RUSTY_V8_SRC_BINDING_PATH" ]] || die "V8 source binding is missing; run pnpm deps:fetch"

rg_bin="$(native_path "$(command -v rg)")"

printf 'building patched Codex %s for %s\n' "$(codex_version "$source_root")" "$WINDOWS_TARGET"
python "$source_root/scripts/build_codex_package.py" \
  --target "$WINDOWS_TARGET" \
  --package-dir "$package_root" \
  --cargo-profile release \
  --rg-bin "$rg_bin" \
  --force

bash "$SCRIPT_DIR/package.sh"
