# PulseDeck

<p align="center">
  <img src="src-tauri/icons/icon.png" width="96" alt="PulseDeck icon" />
</p>

<p align="center">
  <strong>A black-and-white Hyprland display control cockpit for Omarchy.</strong>
</p>

<p align="center">
  <a href="https://discord.gg/YOUR_INVITE_CODE">
    <img alt="Join Discord" src="https://img.shields.io/badge/Discord-Join-000000?style=for-the-badge&logo=discord&logoColor=white&labelColor=111111" />
  </a>
  <a href="https://discord.gg/YOUR_INVITE_CODE">
    <img alt="Discord members" src="https://img.shields.io/discord/YOUR_SERVER_ID?style=for-the-badge&logo=discord&logoColor=white&label=Members&color=000000&labelColor=111111" />
  </a>
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.0-000000?style=for-the-badge&labelColor=111111" />
  <img alt="Linux" src="https://img.shields.io/badge/Linux-AppImage%20%7C%20deb%20%7C%20rpm-000000?style=for-the-badge&logo=linux&logoColor=white&labelColor=111111" />
</p>

PulseDeck helps Hyprland users inspect connected monitors, see advertised refresh-rate modes, generate a safe `monitors.conf`, and apply changes with backups.

## Features

- Reads connected displays with `hyprctl monitors -j`.
- Highlights 120Hz+ opportunities without forcing unsupported modes.
- Generates Hyprland monitor config lines.
- Backs up the existing monitor config before writing.
- Shows config errors after `hyprctl reload`.
- Includes a one-time setup check for administrator authorization.

## Downloads

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
