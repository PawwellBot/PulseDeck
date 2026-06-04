#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGES_DIR="$(mktemp -d)"
trap 'rm -rf "$PAGES_DIR"' EXIT

VERSION="$(node -p "require('./package.json').version")"
DEB="$ROOT_DIR/src-tauri/target/release/bundle/deb/PulseDeck_${VERSION}_amd64.deb"
ARCH_PKG="$ROOT_DIR/packaging/arch/pulsedeck/pulsedeck-${VERSION}-1-x86_64.pkg.tar.zst"
ARCH_ALIAS_PKG="$ROOT_DIR/packaging/arch/pulse-deck/pulse-deck-${VERSION}-1-any.pkg.tar.zst"

if [[ ! -f "$DEB" ]]; then
  echo "Missing deb package: $DEB" >&2
  echo "Run scripts/package-linux.sh --no-bump first." >&2
  exit 1
fi

if [[ ! -f "$ARCH_PKG" ]]; then
  echo "Missing Arch package: $ARCH_PKG" >&2
  echo "Run makepkg in packaging/arch/pulsedeck first." >&2
  exit 1
fi

if [[ ! -f "$ARCH_ALIAS_PKG" ]]; then
  echo "Missing Arch alias package: $ARCH_ALIAS_PKG" >&2
  echo "Run makepkg --nodeps in packaging/arch/pulse-deck first." >&2
  exit 1
fi

mkdir -p "$PAGES_DIR/arch/x86_64"
mkdir -p "$PAGES_DIR/apt/pool/main/p/pulsedeck"
mkdir -p "$PAGES_DIR/apt/dists/stable/main/binary-amd64"

cp "$ARCH_PKG" "$PAGES_DIR/arch/x86_64/"
cp "$ARCH_ALIAS_PKG" "$PAGES_DIR/arch/x86_64/"
(
  cd "$PAGES_DIR/arch/x86_64"
  repo-add pulsedeck.db.tar.gz "$(basename "$ARCH_PKG")" "$(basename "$ARCH_ALIAS_PKG")" >/dev/null
  rm -f pulsedeck.db pulsedeck.files
  cp pulsedeck.db.tar.gz pulsedeck.db
  cp pulsedeck.files.tar.gz pulsedeck.files
)

cp "$DEB" "$PAGES_DIR/apt/pool/main/p/pulsedeck/pulsedeck_${VERSION}_amd64.deb"
(
  cd "$PAGES_DIR/apt"
  dpkg-scanpackages --arch amd64 pool > dists/stable/main/binary-amd64/Packages
  gzip -kf dists/stable/main/binary-amd64/Packages
  python - <<'PY'
from pathlib import Path
from email.utils import formatdate
import hashlib

base = Path('dists/stable')
files = [
    Path('main/binary-amd64/Packages'),
    Path('main/binary-amd64/Packages.gz'),
]
lines = [
    'Origin: PulseDeck',
    'Label: PulseDeck',
    'Suite: stable',
    'Codename: stable',
    f'Date: {formatdate(usegmt=True)}',
    'Architectures: amd64',
    'Components: main',
    'Description: PulseDeck package repository',
    'MD5Sum:',
]
for rel in files:
    data = (base / rel).read_bytes()
    lines.append(f' {hashlib.md5(data).hexdigest()} {len(data)} {rel.as_posix()}')
lines.append('SHA256:')
for rel in files:
    data = (base / rel).read_bytes()
    lines.append(f' {hashlib.sha256(data).hexdigest()} {len(data)} {rel.as_posix()}')
(base / 'Release').write_text('\n'.join(lines) + '\n')
PY
)

touch "$PAGES_DIR/.nojekyll"

cd "$PAGES_DIR"
git init -b gh-pages
git config user.name "PawwellBot"
git config user.email "PawwellBot@users.noreply.github.com"
git add .
git commit -m "Publish package repositories"
git remote add origin https://github.com/PawwellBot/PulseDeck.git
git push -f origin gh-pages
