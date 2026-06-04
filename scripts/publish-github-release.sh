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
  scripts/package-flatpak.sh

Example:
  scripts/publish-github-release.sh pawwellbot/PulseDeck v0.1.0
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPO="$1"
VERSION="$(node -p "require('./package.json').version")"
TAG="${2:-v${VERSION}}"

ASSETS=(
  "src-tauri/target/release/bundle/PulseDeck_${VERSION}_SHA256SUMS.txt"
  "src-tauri/target/release/bundle/appimage/PulseDeck_${VERSION}_amd64.AppImage"
  "src-tauri/target/release/bundle/deb/PulseDeck_${VERSION}_amd64.deb"
  "src-tauri/target/release/bundle/rpm/PulseDeck-${VERSION}-1.x86_64.rpm"
  "src-tauri/target/release/bundle/flatpak/PulseDeck_${VERSION}_x86_64.flatpak"
)

for asset in "${ASSETS[@]}"; do
  if [[ ! -f "$asset" ]]; then
    echo "Missing release asset: $asset" >&2
    echo "Run scripts/package-linux.sh --no-bump first." >&2
    exit 1
  fi
done

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" "${ASSETS[@]}" --repo "$REPO" --clobber
  gh release edit "$TAG" --repo "$REPO" --title "PulseDeck ${VERSION}" --notes-file RELEASE_NOTES.md
else
  gh release create "$TAG" "${ASSETS[@]}" \
    --repo "$REPO" \
    --title "PulseDeck ${VERSION}" \
    --notes-file RELEASE_NOTES.md
fi
