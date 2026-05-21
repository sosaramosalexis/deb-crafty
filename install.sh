#!/usr/bin/env bash
set -u

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[*]${NC} $1"; }
err()  { echo -e "${RED}[-]${NC} $1"; }

BASE_DIR="/var/opt/minecraft/crafty"

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
    echo ""
    warn "Make sure port 8443 is open in your firewall if accessing remotely."
    echo ""
}

detect_paths() {
    if [[ -d "$BASE_DIR/crafty-4" ]]; then
        CRAFTY_DIR="$BASE_DIR/crafty-4"
    else
        CRAFTY_DIR="$BASE_DIR"
    fi
    CREDS_FILE="$CRAFTY_DIR/app/config/default-creds.txt"
    RUN_SCRIPT="$BASE_DIR/run_crafty.sh"
    if [[ ! -f "$RUN_SCRIPT" ]]; then
        RUN_SCRIPT="$CRAFTY_DIR/run_crafty.sh"
    fi
}

show_creds() {
    read -rp "  Show default credentials? [y/N]: " ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        if [[ -f "$CREDS_FILE" ]]; then
            echo ""
            log "Default credentials (change on first login):"
            echo ""
            cat "$CREDS_FILE"
            echo ""
        else
            warn "Credentials file not found at $CREDS_FILE"
            info "Try: sudo cat $BASE_DIR/*/app/config/default-creds.txt"
        fi
    fi
}

start_crafty() {
    info "Crafty runs as the 'crafty' user."
    echo ""
    read -rp "  Start Crafty Controller now? [y/N]: " ans
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        if [[ -x "$RUN_SCRIPT" ]]; then
            log "Starting Crafty Controller..."
            sudo -u crafty bash -c "cd $(dirname "$RUN_SCRIPT") && ./$(basename "$RUN_SCRIPT")"
        else
            err "Run script not found at $RUN_SCRIPT"
            info "Start manually: sudo su crafty && cd $BASE_DIR && ls"
        fi
    else
        info "To start manually later:"
        echo "  sudo su crafty"
        echo "  cd $BASE_DIR"
        echo "  ls  (find the run script)"
        echo "  ./run_crafty.sh"
    fi
}

# --- Main ---
echo ""
log "Crafty Controller — Minecraft Server Manager"
echo ""

check_root
install_deps
install_crafty
detect_paths
show_post_guide
show_creds
start_crafty

log "Done."
