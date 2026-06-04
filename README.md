# PulseDeck

<p align="center">
  <img src="src-tauri/icons/icon.png" width="96" alt="PulseDeck icon" />
</p>

<p align="center">
  <strong>A Hyprland display control cockpit for Omarchy.</strong>
</p>

<p align="center">
  <a href="https://discord.gg/NbCfSFj4fd">
    <img alt="Join Discord" src="https://img.shields.io/badge/Discord-Join-5865F2?style=for-the-badge&logo=discord&logoColor=white&labelColor=404EED" />
  </a>
  <a href="https://discord.gg/NbCfSFj4fd">
    <img alt="Discord members" src="https://img.shields.io/discord/1495367426571899022?style=for-the-badge&logo=discord&logoColor=white&label=Members&color=5865F2&labelColor=404EED" />
  </a>
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.0-1BD96A?style=for-the-badge&labelColor=202421" />
  <img alt="Linux" src="https://img.shields.io/badge/Linux-AppImage%20%7C%20deb%20%7C%20rpm-35D6D0?style=for-the-badge&logo=linux&logoColor=white&labelColor=202421" />
</p>

PulseDeck helps Hyprland users inspect connected monitors, see advertised refresh-rate modes, generate a safe `monitors.conf`, and apply changes with backups.

## First Release

PulseDeck `0.1.0` is the first public Linux release of the app. It is built for Hyprland and Omarchy users who want a safer, more visual way to understand and manage their display setup without hand-editing monitor config every time something changes.

The app reads connected displays through `hyprctl`, shows each monitor's current resolution, scale, position, and refresh rate, then compares that state against the modes Hyprland says the hardware actually advertises. PulseDeck does not try to force unsupported refresh rates. Instead, it helps you see when 120Hz or higher is available, when a lower resolution may be needed, and when a cable, dock, adapter, GPU port, or EDID issue may be limiting the display.

For this first version, the workflow is intentionally focused: scan monitors, preview generated Hyprland monitor lines, apply them with a backup, reload Hyprland, and review config errors if anything goes wrong. It also includes a one-time setup authorization check, a black-and-white interface, profile-oriented views, diagnostics, and backup visibility. PulseDeck is not trying to replace every display tool; it is a practical control panel for making monitor changes more understandable, reversible, and calm.

## Features

- Reads connected displays with `hyprctl monitors -j`.
- Highlights 120Hz+ opportunities without forcing unsupported modes.
- Generates Hyprland monitor config lines.
- Backs up the existing monitor config before writing.
- Shows config errors after `hyprctl reload`.
- Includes a one-time setup check for administrator authorization.

## Install

GitHub Pages is only used to host package repository files. The install instructions live here in the repository README.

### Arch / Omarchy

Add the PulseDeck pacman repository once:

```bash
sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[pulsedeck]
SigLevel = Optional TrustAll
Server = https://pawwellbot.github.io/PulseDeck/arch/x86_64
EOF
```

Then install PulseDeck:

```bash
sudo pacman -S pulsedeck
```

The compatibility alias works too:

```bash
sudo pacman -S pulse-deck
```

### Debian / Ubuntu

Add the PulseDeck apt repository once, then install:

```bash
echo "deb [trusted=yes] https://pawwellbot.github.io/PulseDeck/apt stable main" | sudo tee /etc/apt/sources.list.d/pulsedeck.list
sudo apt update
sudo apt install pulsedeck
```

The repositories are unsigned for the first release, so the install snippets explicitly opt into trusting the PulseDeck repository.

### AppImage

```bash
curl -LO https://github.com/PawwellBot/PulseDeck/releases/download/v0.1.0/PulseDeck_0.1.0_amd64.AppImage
chmod +x PulseDeck_0.1.0_amd64.AppImage
./PulseDeck_0.1.0_amd64.AppImage
```

### Manual Debian / Ubuntu Package

```bash
curl -LO https://github.com/PawwellBot/PulseDeck/releases/download/v0.1.0/PulseDeck_0.1.0_amd64.deb
sudo apt install ./PulseDeck_0.1.0_amd64.deb
```

### Fedora / RHEL

```bash
curl -LO https://github.com/PawwellBot/PulseDeck/releases/download/v0.1.0/PulseDeck-0.1.0-1.x86_64.rpm
sudo dnf install ./PulseDeck-0.1.0-1.x86_64.rpm
```

### Checksums

```bash
curl -LO https://github.com/PawwellBot/PulseDeck/releases/download/v0.1.0/PulseDeck_0.1.0_SHA256SUMS.txt
sha256sum -c PulseDeck_0.1.0_SHA256SUMS.txt
```

### AUR

The AUR package files are prepared in:

```text
packaging/aur/pulsedeck-bin/
```

The package is named `pulsedeck-bin` and provides `pulsedeck`. Publishing to AUR requires an AUR account with this machine's SSH public key added:

```bash
ssh -T aur@aur.archlinux.org
scripts/publish-aur.sh
```

After it is published to AUR, install it with an AUR helper:

```bash
yay -S pulsedeck-bin
```

## Build

```bash
npm install
npm run check
npm run package:linux
```

Packages are written to:

```text
src-tauri/target/release/bundle/
```

## Notes

PulseDeck manages the user Hyprland monitor file:

```text
~/.config/hypr/monitors.conf
```

Backups are stored at:

```text
~/.config/hypr/pulsedeck-backups/
```

The setup authorization command is:

```bash
pkexec true
```

It is only a one-time authorization check. PulseDeck does not keep running as root.
