#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/package-linux.sh [--no-bump]
  scripts/package-linux.sh patch
  scripts/package-linux.sh minor
  scripts/package-linux.sh major
  scripts/package-linux.sh prerelease [tag]
  scripts/package-linux.sh set <version>

Builds all Linux package formats supported by this Tauri project:
  - AppImage
  - deb
  - rpm

Examples:
  scripts/package-linux.sh --no-bump
  scripts/package-linux.sh patch
  scripts/package-linux.sh minor
  scripts/package-linux.sh prerelease beta
  scripts/package-linux.sh set 1.2.3
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" != "" && "${1:-}" != "--no-bump" ]]; then
  scripts/bump-version.sh "$@"
fi

VERSION="$(node -p "require('./package.json').version")"
BUNDLES=(appimage deb rpm)
MISSING_TOOLS=()

if ! command -v dpkg-deb >/dev/null 2>&1; then
  MISSING_TOOLS+=(dpkg-deb)
fi

if ! command -v rpmbuild >/dev/null 2>&1; then
  MISSING_TOOLS+=(rpmbuild)
fi

if [[ ${#MISSING_TOOLS[@]} -gt 0 && "${PULSEDECK_SKIP_PACKAGE_DEPS_CHECK:-}" != "1" ]]; then
  echo "Missing Linux packaging tools: ${MISSING_TOOLS[*]}" >&2
  echo >&2
  echo "Install the distro packages that provide those commands, then rerun this script." >&2
  echo "On Arch/Omarchy, this usually means installing dpkg and rpm-tools/rpm packages." >&2
  echo "Set PULSEDECK_SKIP_PACKAGE_DEPS_CHECK=1 to let Tauri try anyway." >&2
  exit 1
fi

echo "Building PulseDeck ${VERSION}"
echo "Linux bundle targets: ${BUNDLES[*]}"

export NO_STRIP="${NO_STRIP:-1}"

npm run tauri -- build --ci --bundles "${BUNDLES[@]}"

echo
echo "Built Linux packages:"
find src-tauri/target/release/bundle -type f \
  \( -name '*.AppImage' -o -name '*.deb' -o -name '*.rpm' \) \
  -print | sort
