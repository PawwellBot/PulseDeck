#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/publish-aur.sh

Publishes packaging/aur/pulsedeck-bin to the AUR.

Before running:
  1. Create/log in to your AUR account.
  2. Add this machine's SSH public key to your AUR account.
  3. Verify SSH:
     ssh -T aur@aur.archlinux.org

The AUR package name is pulsedeck-bin and provides pulsedeck.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUR_SRC="$ROOT_DIR/packaging/aur/pulsedeck-bin"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

git clone ssh://aur@aur.archlinux.org/pulsedeck-bin.git "$WORK_DIR/pulsedeck-bin"
cp "$AUR_SRC/PKGBUILD" "$AUR_SRC/.SRCINFO" "$WORK_DIR/pulsedeck-bin/"

cd "$WORK_DIR/pulsedeck-bin"
git add PKGBUILD .SRCINFO

if git diff --cached --quiet; then
  echo "AUR package is already up to date."
  exit 0
fi

git commit -m "Release pulsedeck-bin 0.1.0-1"
git push
