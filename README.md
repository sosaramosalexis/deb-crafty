<p align="center">
  <img src="https://placehold.co/120x179" width="90" alt="deb-crafty logo">
  <!-- Replace src with your 784×1168 logo image (displayed at 90px wide) -->
</p>

[![GitHub](https://img.shields.io/badge/GitHub-sosaramosalexis/deb-crafty-181717?logo=github)](https://github.com/sosaramosalexis/deb-crafty)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-blue?logo=gnu-bash)]()
[![Platform](https://img.shields.io/badge/platform-Linux-blue)]()

# Crafty Controller — Minecraft Server Manager

Installs [Crafty Controller](https://gitlab.com/crafty-controller/crafty-installer-4.0), a web-based Minecraft server manager.

## Usage

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/sosaramosalexis/deb-crafty/main/install.sh)
```

Auto-install (skip menu):
```bash
sudo bash <(curl -fsSL ...) install
```

## Options

| # | Option | Description |
|---|--------|-------------|
| 1 | Install Crafty Controller | Full install: deps, clone, installer, `run crafty` alias |
| 2 | Clean directories for new install | Removes `/var/opt/minecraft/crafty`, `crafty` user, and profile alias |
| 3 | Show default credentials | Display auto-generated credentials from the latest install |
| 4 | Start Crafty Controller server | Launch the Crafty service manually |

## After Install

- Access the web UI at `http://<hostname>:8443`
- Start again anytime with: `run crafty`
- View credentials via menu option 3
- Default install path: `/var/opt/minecraft/crafty`
