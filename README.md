# Crafty Controller — Minecraft Server Manager

Installs [Crafty Controller](https://gitlab.com/crafty-controller/crafty-installer-4.0), a web-based Minecraft server manager.

## Usage

Run directly:
```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/alsosram/deb-crafty/main/install.sh)
```

Run with auto-install (skip menu):
```bash
sudo bash <(curl -fsSL ...) install
```

## Options

| # | Option | Description |
|---|--------|-------------|
| 1 | Install Crafty Controller | Full install: deps, clone, installer, creds prompt, start prompt, `run crafty` alias |
| 2 | Clean directories for new install | Removes `/var/opt/minecraft/crafty`, `crafty` user, and profile alias |

## After Install

- Access the web UI at `http://<hostname>:8443`
- Show default credentials when prompted during install
- Start again anytime with: `run crafty`
- Default install path: `/var/opt/minecraft/crafty`
