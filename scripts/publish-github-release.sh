#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/publish-github-release.sh <owner/repo> [tag]

Uploads the built Linux packages to a GitHub release.

Before running:
  gh auth login
  scripts/package-linux.sh --no-bump

Example:
  scripts/publish-github-release.sh pawwellbot/PulseDeck v0.1.0
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "" ]]; then
  usage
  exit 0
fi

REPO="$1"
TAG="${2:-v0.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ASSETS=(
  "src-tauri/target/release/bundle/PulseDeck_0.1.0_SHA256SUMS.txt"
  "src-tauri/target/release/bundle/appimage/PulseDeck_0.1.0_amd64.AppImage"
  "src-tauri/target/release/bundle/deb/PulseDeck_0.1.0_amd64.deb"
  "src-tauri/target/release/bundle/rpm/PulseDeck-0.1.0-1.x86_64.rpm"
)

for asset in "${ASSETS[@]}"; do
  if [[ ! -f "$asset" ]]; then
    echo "Missing release asset: $asset" >&2
    echo "Run scripts/package-linux.sh --no-bump first." >&2
    exit 1
  fi
done

gh release create "$TAG" "${ASSETS[@]}" \
  --repo "$REPO" \
  --title "PulseDeck 0.1.0" \
  --notes-file RELEASE_NOTES.md
