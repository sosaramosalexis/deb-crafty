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

clean_install() {
    echo ""
    warn "This will remove ALL Crafty Controller files and directories."
    warn "Action cannot be undone."
    echo ""
    read -rp "  Type 'yes' to confirm clean: " ans
    if [[ "$ans" != "yes" ]]; then
        log "Clean cancelled."
        return
    fi

    log "Stopping Crafty if running..."
    pkill -f run_crafty.sh 2>/dev/null || true

    log "Removing $BASE_DIR..."
    rm -rf "$BASE_DIR"

    log "Removing crafty user if exists..."
    id crafty &>/dev/null && userdel -r crafty 2>/dev/null

    log "Removing /etc/profile.d/crafty.sh..."
    rm -f /etc/profile.d/crafty.sh

    log "Clean complete. Ready for a fresh install."
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
        info "To start manually later, type: run crafty"
    fi
}

setup_alias() {
    local profile_file="/etc/profile.d/crafty.sh"
    if [[ ! -f "$profile_file" ]]; then
        log "Creating 'run crafty' command..."
        cat > "$profile_file" << 'EOF'
run() {
    case "$1" in
        crafty)
            sudo -u crafty bash -c 'cd /var/opt/minecraft/crafty && ./run_crafty.sh'
            ;;
        *)
            echo "Usage: run crafty"
            ;;
    esac
}
EOF
        chmod +x "$profile_file"
        source "$profile_file"
        log "Type 'run crafty' to start. (source $profile_file in existing sessions)"
    else
        info "'run crafty' already set up."
    fi
}

show_banner() {
    echo ""
    echo -e "${GREEN}  Crafty Controller — Minecraft Server Manager${NC}"
    echo ""
}

show_menu() {
    echo ""
    info "Select an option:"
    echo ""
    echo "  ${GREEN}[1]${NC} Install Crafty Controller"
    echo "  ${GREEN}[2]${NC} Clean directories for new install"
    echo ""
    echo "  ${CYAN}[Q]${NC} Quit"
    echo ""
}

run_install_flow() {
    install_deps
    install_crafty
    detect_paths
    echo ""
    log "Crafty Controller installation complete!"
    echo ""
    info "Access the web interface at: http://$(hostname -I | awk '{print $1}'):8443"
    echo ""
    warn "Make sure port 8443 is open in your firewall if accessing remotely."
    echo ""
    show_creds
    start_crafty
    setup_alias
}

# --- Main ---
check_root
show_banner

if [[ $# -ge 1 && "$1" == "install" ]]; then
    run_install_flow
    log "Done."
    exit 0
fi

while true; do
    show_menu
    read -rp "  Enter choice [1-2]: " choice
    case "$choice" in
        1) run_install_flow ;;
        2) clean_install ;;
        [Qq]) log "Goodbye."; exit 0 ;;
        *) err "Invalid choice." ;;
    esac
    echo ""
    read -rp "  Press Enter to continue..."
done
