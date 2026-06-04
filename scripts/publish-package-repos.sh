#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGES_DIR="$(mktemp -d)"
trap 'rm -rf "$PAGES_DIR"' EXIT

VERSION="$(node -p "require('./package.json').version")"
DEB="$ROOT_DIR/src-tauri/target/release/bundle/deb/PulseDeck_${VERSION}_amd64.deb"
ARCH_PKG="$ROOT_DIR/packaging/arch/pulsedeck/pulsedeck-${VERSION}-1-x86_64.pkg.tar.zst"

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

mkdir -p "$PAGES_DIR/arch/x86_64"
mkdir -p "$PAGES_DIR/apt/pool/main/p/pulsedeck"
mkdir -p "$PAGES_DIR/apt/dists/stable/main/binary-amd64"

cp "$ARCH_PKG" "$PAGES_DIR/arch/x86_64/"
(
  cd "$PAGES_DIR/arch/x86_64"
  repo-add pulsedeck.db.tar.gz "$(basename "$ARCH_PKG")" >/dev/null
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

cat > "$PAGES_DIR/index.html" <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PulseDeck Package Repositories</title>
    <style>
      body { margin: 0; background: #0b0f14; color: #f4f4f5; font-family: Inter, ui-sans-serif, system-ui, sans-serif; line-height: 1.6; }
      main { max-width: 880px; margin: 0 auto; padding: 48px 20px; }
      h1 { font-size: clamp(2rem, 5vw, 4rem); line-height: 1.05; margin: 0 0 12px; }
      h2 { margin-top: 36px; }
      p { color: #cbd5e1; }
      pre { overflow-x: auto; background: #000; border: 1px solid rgba(255,255,255,.14); border-radius: 8px; padding: 16px; }
      code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
      a { color: #7cf7b8; }
    </style>
  </head>
  <body>
    <main>
      <h1>PulseDeck packages</h1>
      <p>Install PulseDeck from package-manager repositories instead of downloading files manually.</p>

      <h2>Arch / Omarchy</h2>
      <pre><code>sudo tee -a /etc/pacman.conf &gt;/dev/null &lt;&lt;'EOF'

[pulsedeck]
SigLevel = Optional TrustAll
Server = https://pawwellbot.github.io/PulseDeck/arch/x86_64
EOF
sudo pacman -Sy pulsedeck</code></pre>

      <h2>Debian / Ubuntu</h2>
      <pre><code>echo "deb [trusted=yes] https://pawwellbot.github.io/PulseDeck/apt stable main" | sudo tee /etc/apt/sources.list.d/pulsedeck.list
sudo apt update
sudo apt install pulsedeck</code></pre>

      <p>Source and releases: <a href="https://github.com/PawwellBot/PulseDeck">github.com/PawwellBot/PulseDeck</a></p>
    </main>
  </body>
</html>
HTML

cd "$PAGES_DIR"
git init -b gh-pages
git config user.name "PawwellBot"
git config user.email "PawwellBot@users.noreply.github.com"
git add .
git commit -m "Publish package repositories"
git remote add origin https://github.com/PawwellBot/PulseDeck.git
git push -f origin gh-pages
