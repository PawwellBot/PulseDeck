#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/bump-version.sh patch
  scripts/bump-version.sh minor
  scripts/bump-version.sh major
  scripts/bump-version.sh prerelease [tag]
  scripts/bump-version.sh set <version>

Examples:
  scripts/bump-version.sh patch
  scripts/bump-version.sh minor
  scripts/bump-version.sh prerelease beta
  scripts/bump-version.sh set 1.2.3
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="$1"
EXTRA="${2:-}"

cd "$ROOT_DIR"

NEW_VERSION="$(node scripts/bump-version.mjs "$MODE" "$EXTRA")"

cargo check --manifest-path src-tauri/Cargo.toml >/dev/null

echo "PulseDeck version updated to ${NEW_VERSION}"
