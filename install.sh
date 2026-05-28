#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/var/opt/minecraft/crafty"

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "This script must be run as root (use sudo)."
        exit 1
    fi
}

if ! command -v whiptail >/dev/null 2>&1; then
    echo "Installing whiptail for interactive menu..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y -qq whiptail
fi

check_root

install_deps() {
    echo "Updating package list and installing dependencies..."
    apt update && apt upgrade -y
    apt install git whiptail -y
}

install_crafty() {
    echo "Cloning Crafty Controller installer..."
    cd /tmp
    rm -rf crafty-installer-4.0 2>/dev/null
    git clone https://gitlab.com/crafty-controller/crafty-installer-4.0.git
    cd crafty-installer-4.0
    echo "Running Crafty Controller installer..."
    ./install_crafty.sh
}

clean_install() {
    if ! whiptail --yesno "This will remove ALL Crafty Controller files and directories.\nAction cannot be undone." 8 60; then
        return
    fi

    echo "Stopping Crafty if running..."
    pkill -f run_crafty.sh 2>/dev/null || true

    echo "Removing $BASE_DIR..."
    rm -rf "$BASE_DIR"

    echo "Removing crafty user if exists..."
    id crafty &>/dev/null && userdel -r crafty 2>/dev/null

    echo "Removing /etc/profile.d/crafty.sh..."
    rm -f /etc/profile.d/crafty.sh

    echo "Clean complete. Ready for a fresh install."
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
    detect_paths
    if [[ -f "$CREDS_FILE" ]]; then
        local content
        content=$(cat "$CREDS_FILE")
        whiptail --msgbox "Default credentials (change on first login):\n\n${content}" 15 70
    else
        whiptail --msgbox "Credentials not yet generated.\n\nStart Crafty first (option 4), then\ncheck this file:\n${CREDS_FILE}" 10 70
    fi
}

start_crafty() {
    detect_paths
    if [[ ! -x "$RUN_SCRIPT" ]]; then
        whiptail --msgbox "Run script not found at:\n${RUN_SCRIPT}\n\nInstall Crafty first." 8 60
        return
    fi
    if ! id crafty &>/dev/null; then
        whiptail --msgbox "Crafty user does not exist.\nInstall Crafty first." 8 50
        return
    fi
    if whiptail --yesno "Start Crafty Controller now?" 8 40; then
        local script_dir
        script_dir=$(dirname "$RUN_SCRIPT")
        nohup sudo -u crafty bash -c "cd '$script_dir' && ./$(basename "$RUN_SCRIPT")" > /var/log/crafty.log 2>&1 &
        whiptail --msgbox "Crafty started in background.\n\nLogs: /var/log/crafty.log\nPID: $!" 8 60
    fi
}

setup_alias() {
    local profile_file="/etc/profile.d/crafty.sh"
    if [[ ! -f "$profile_file" ]]; then
        echo "Creating 'run crafty' command..."
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
        echo "Type 'run crafty' to start. (source /etc/profile.d/crafty.sh in existing sessions)"
    else
        echo "'run crafty' already set up."
    fi
}

run_install_flow() {
    install_deps
    install_crafty
    setup_alias
    local ip
    ip=$(hostname -I | awk '{print $1}')
    whiptail --msgbox "Crafty Controller installation complete!\n\nAccess the web interface at:\nhttp://${ip}:8443\n\nStart Crafty (option 4) to generate\ndefault credentials, then view with\noption 3.\n\nMake sure port 8443 is open." 15 60
}

if [[ $# -ge 1 && "$1" == "install" ]]; then
    run_install_flow
    echo "Done."
    exit 0
fi

while true; do
    CHOICE=$(whiptail --menu "Crafty Controller — Minecraft Server Manager" 14 58 4 \
        "1" "Install Crafty Controller" \
        "2" "Clean directories for new install" \
        "3" "Show default credentials" \
        "4" "Start Crafty Controller server" \
        3>&1 1>&2 2>&3)
    case "$CHOICE" in
        "") break ;;
        1) run_install_flow ;;
        2) clean_install ;;
        3) show_creds ;;
        4) start_crafty ;;
    esac
done
