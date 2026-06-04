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

## Package Repositories

PulseDeck can be installed from the hosted package repositories after adding the source once.

Arch / Omarchy:

```bash
sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[pulsedeck]
SigLevel = Optional TrustAll
Server = https://pawwellbot.github.io/PulseDeck/arch/x86_64
EOF
sudo pacman -Sy pulsedeck
```

The compatibility alias also works after the repository has been added:

```bash
sudo pacman -S pulse-deck
```

Debian / Ubuntu:

```bash
echo "deb [trusted=yes] https://pawwellbot.github.io/PulseDeck/apt stable main" | sudo tee /etc/apt/sources.list.d/pulsedeck.list
sudo apt update
sudo apt install pulsedeck
```

The repositories are unsigned for the first release, so the install snippets explicitly opt into trusting the PulseDeck repository.

## Direct Downloads

Linux builds are published as:

- `PulseDeck_0.1.0_amd64.AppImage`
- `PulseDeck_0.1.0_amd64.deb`
- `PulseDeck-0.1.0-1.x86_64.rpm`

## Install

AppImage:

```bash
chmod +x PulseDeck_0.1.0_amd64.AppImage
./PulseDeck_0.1.0_amd64.AppImage
```

Debian/Ubuntu:

```bash
sudo apt install ./PulseDeck_0.1.0_amd64.deb
```

Fedora/RHEL:

```bash
sudo dnf install ./PulseDeck-0.1.0-1.x86_64.rpm
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

## AUR

The AUR package files are prepared in:

```text
packaging/aur/pulsedeck-bin/
```

The package is named `pulsedeck-bin` and provides `pulsedeck`. Publishing to AUR requires an AUR account with this machine's SSH public key added:

```bash
ssh -T aur@aur.archlinux.org
scripts/publish-aur.sh
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
