#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/package-flatpak.sh

Builds a single-file Flatpak bundle for the current PulseDeck version.

The script uses local flatpak-builder when available. If it is not installed
and Docker is available, it builds inside an Arch Linux container.
USAGE
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

VERSION="$(node -p "require('./package.json').version")"
APP_ID="dev.pulsedeck.desktop"
MANIFEST="packaging/flatpak/${APP_ID}.yml"
OUTPUT_DIR="src-tauri/target/release/bundle/flatpak"
OUTPUT="${OUTPUT_DIR}/PulseDeck_${VERSION}_x86_64.flatpak"

mkdir -p "$OUTPUT_DIR"

build_flatpak() {
  local repo_dir="$1"
  local build_dir="$2"

  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install --user --no-related -y flathub org.gnome.Platform//50 org.gnome.Sdk//50

  flatpak-builder \
    --user \
    --force-clean \
    --state-dir=src-tauri/target/flatpak-state \
    --default-branch=stable \
    --install-deps-from=flathub \
    --repo="$repo_dir" \
    "$build_dir" \
    "$MANIFEST"

  flatpak build-bundle \
    "$repo_dir" \
    "$OUTPUT" \
    "$APP_ID" \
    stable \
    --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo
}

if command -v flatpak-builder >/dev/null 2>&1 && command -v flatpak >/dev/null 2>&1; then
  build_flatpak \
    "src-tauri/target/release/bundle/flatpak/repo" \
    "src-tauri/target/flatpak-build"
elif command -v docker >/dev/null 2>&1; then
  docker run --rm --privileged \
    -e "HOST_UID=$(id -u)" \
    -e "HOST_GID=$(id -g)" \
    -e "VERSION=$VERSION" \
    -e "APP_ID=$APP_ID" \
    -v "$ROOT_DIR:/src" \
    -v pulsedeck-pacman-cache:/var/cache/pacman/pkg \
    -v pulsedeck-flatpak-cache:/root/.local/share/flatpak \
    -w /src \
    archlinux:latest \
    bash -lc '
      set -euo pipefail
      pacman -Sy --noconfirm flatpak flatpak-builder
      flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak install --user --no-related -y flathub org.gnome.Platform//50 org.gnome.Sdk//50
      flatpak-builder \
        --user \
        --force-clean \
        --state-dir=/tmp/pulsedeck-flatpak-state \
        --default-branch=stable \
        --install-deps-from=flathub \
        --repo=/tmp/pulsedeck-flatpak-repo \
        /tmp/pulsedeck-flatpak-build \
        packaging/flatpak/dev.pulsedeck.desktop.yml
      flatpak build-bundle \
        /tmp/pulsedeck-flatpak-repo \
        "/src/src-tauri/target/release/bundle/flatpak/PulseDeck_${VERSION}_x86_64.flatpak" \
        "$APP_ID" \
        stable \
        --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo
      chown "${HOST_UID}:${HOST_GID}" "/src/src-tauri/target/release/bundle/flatpak/PulseDeck_${VERSION}_x86_64.flatpak"
    '
else
  echo "Missing flatpak-builder/flatpak, and Docker is not available for the fallback build." >&2
  exit 1
fi

echo "Built Flatpak bundle:"
echo "$OUTPUT"
