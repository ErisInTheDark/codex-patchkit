#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/lib.sh"

require_command git
require_command mktemp
require_command pnpm
require_command python

source_root="$(bash "$SCRIPT_DIR/prepare-source.sh")"
key="$(build_key)"
canonical_package="$WORK_ROOT/build/$key/codex-package"
[[ -f "$canonical_package/codex-package.json" ]] || die "built Codex package is missing; run pnpm build first"

upstream_version="$(codex_version "$source_root")"
patches="$(patch_digest)"
npm_version="$upstream_version-patchkit.${patches:0:12}"
stage_parent="$WORK_ROOT/npm-stage"
mkdir -p "$stage_parent" "$DIST_ROOT"
stage="$(mktemp -d "$stage_parent/$key.XXXXXX")"
mkdir -p "$stage/bin" "$stage/vendor/$WINDOWS_TARGET"

cp "$source_root/codex-cli/bin/codex.js" "$stage/bin/codex.js"
cp -R "$canonical_package/." "$stage/vendor/$WINDOWS_TARGET/"
cp "$PROJECT_ROOT/LICENSE" "$stage/LICENSE"
cp "$PROJECT_ROOT/NOTICE" "$stage/NOTICE"
cp "$PROJECT_ROOT/README.md" "$stage/README.md"

cat > "$stage/package.json" <<EOF
{
  "name": "@openai/codex",
  "version": "$npm_version",
  "description": "Locally built Codex with codex-patchkit patches.",
  "license": "Apache-2.0",
  "bin": {
    "codex": "bin/codex.js"
  },
  "type": "module",
  "engines": {
    "node": ">=16"
  },
  "files": [
    "LICENSE",
    "NOTICE",
    "README.md",
    "bin/codex.js",
    "vendor"
  ]
}
EOF

(
  cd "$stage"
  pnpm pack --pack-destination "$DIST_ROOT"
)

tarball="$DIST_ROOT/openai-codex-$npm_version.tgz"
[[ -f "$tarball" ]] || die "pnpm did not create the expected tarball: $tarball"
printf '%s\n' "$(native_path "$tarball")" > "$(latest_tarball_file)"
printf 'built installable package: %s\n' "$tarball"
