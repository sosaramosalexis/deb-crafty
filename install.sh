#!/usr/bin/env bash
set -u

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[*]${NC} $1"; }
err()  { echo -e "${RED}[-]${NC} $1"; }

INSTALL_DIR="/var/opt/minecraft/crafty"

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        err "This script must be run as root (use sudo)."
        exit 1
    fi
}

install_deps() {
    log "Updating package list and installing dependencies..."
    apt update && apt upgrade -y
    apt install git -y
}

install_crafty() {
    log "Cloning Crafty Controller installer..."
    cd /tmp
    rm -rf crafty-installer-4.0 2>/dev/null
    git clone https://gitlab.com/crafty-controller/crafty-installer-4.0.git
    cd crafty-installer-4.0

    log "Running Crafty Controller installer..."
    ./install_crafty.sh
}

show_post_guide() {
    echo ""
    log "Crafty Controller installation complete!"
    echo ""
    info "Access the web interface at: http://$(hostname -I | awk '{print $1}'):8443"
    info "Default credentials are shown at the end of the installer output above."
    echo ""
    warn "Make sure port 8443 is open in your firewall if accessing remotely."
    echo ""
}

start_crafty() {
    info "Crafty runs as the 'crafty' user."
    echo ""
    read -rp "  Start Crafty Controller now? [y/N]: " ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        log "Starting Crafty Controller..."
        sudo -u crafty bash -c "cd $INSTALL_DIR && ./run_crafty.sh"
    else
        info "To start manually later:"
        echo "  sudo -u crafty bash -c 'cd $INSTALL_DIR && ./run_crafty.sh'"
    fi
}

# --- Main ---
echo ""
log "Crafty Controller — Minecraft Server Manager"
echo ""

check_root
install_deps
install_crafty
show_post_guide
start_crafty

log "Done."
