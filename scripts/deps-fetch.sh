#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command cargo
require_command python
require_command git
activate_codex_rust_toolchain

[[ -f "$CODEX_ROOT/codex-rs/Cargo.lock" ]] || die "initialize the codex/ submodule first"
source_root="$(bash "$SCRIPT_DIR/prepare-source.sh")"

CARGO_HOME_DIR="$WORK_ROOT/cargo"
V8_CACHE_DIR="$WORK_ROOT/v8"
mkdir -p "$CARGO_HOME_DIR" "$V8_CACHE_DIR"

cat > "$CARGO_HOME_DIR/config.toml" <<'EOF'
[net]
offline = true
EOF

export CARGO_HOME="$(native_path "$CARGO_HOME_DIR")"
export CARGO_TARGET_DIR="$(native_path "$TARGET_ROOT")"
export CARGO_NET_OFFLINE=false

printf 'fetching Cargo dependencies into the guarded generated lockfile for %s\n' "$WINDOWS_TARGET"
printf 'using %s\n' "$(cargo --version)"
cargo fetch \
  --target "$WINDOWS_TARGET" \
  --manifest-path "$source_root/codex-rs/Cargo.toml"

printf 'checking the generated release lockfile delta\n'
python - "$CODEX_ROOT/codex-rs/Cargo.lock" "$source_root/codex-rs/Cargo.lock" "$(codex_version "$source_root")" <<'PY'
from pathlib import Path
import sys

pristine_path = Path(sys.argv[1])
generated_path = Path(sys.argv[2])
release_version = sys.argv[3]
pristine = pristine_path.read_text(encoding="utf-8").splitlines()
generated = generated_path.read_text(encoding="utf-8").splitlines()

if len(pristine) != len(generated):
    raise SystemExit("generated Cargo.lock added or removed lines")

allowed_before = 'version = "0.0.0"'
allowed_after = f'version = "{release_version}"'
changed = 0
for line_number, (before, after) in enumerate(zip(pristine, generated), start=1):
    if before == after:
        continue
    if before == allowed_before and after == allowed_after:
        changed += 1
        continue
    raise SystemExit(
        f"unexpected generated Cargo.lock change at line {line_number}: {before!r} -> {after!r}"
    )

print(f"accepted {changed} workspace version normalizations")
PY

printf 'fetching checksum-verified Codex V8 artifacts for %s\n' "$WINDOWS_TARGET"
export PYTHONPATH="$CODEX_ROOT/scripts"
export CODEX_V8_CACHE="$(native_path "$V8_CACHE_DIR")"
export CODEX_V8_TARGET="$WINDOWS_TARGET"
python -c 'import os; from pathlib import Path; from codex_package.targets import TARGET_SPECS; from codex_package.v8 import fetch_codex_v8_artifacts; pair = fetch_codex_v8_artifacts(TARGET_SPECS[os.environ["CODEX_V8_TARGET"]], cache_root=Path(os.environ["CODEX_V8_CACHE"])); print(pair.archive); print(pair.binding)'

export CARGO_NET_OFFLINE=true
printf 'checking that the Windows dependency graph resolves offline\n'
cargo metadata \
  --locked \
  --offline \
  --filter-platform "$WINDOWS_TARGET" \
  --format-version 1 \
  --manifest-path "$source_root/codex-rs/Cargo.toml" \
  >/dev/null

printf 'dependency seed is complete for Codex %s\n' "$(codex_version)"
