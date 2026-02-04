#!/usr/bin/env bash
set -e

# --- HELPERS ---
select_option() {
    local prompt="$1"; shift
    printf "%s\n" "$@" | fzf --height 40% --prompt="> $prompt: "
}

# --- FUNCTIONS ---

check_network() {
    if [[ $(select_option "Internetverbindung?" "Bereits aktiv" "Jetzt einrichten (nmtui)") == *"nmtui"* ]]; then
    	nmtui
    fi
}

collect_inputs() {
    # Username & host
    read -p "System-Username [silas]: " OS_USER
    OS_USER=${OS_USER:-"silas"}
    read -p "Hostname eingeben: " HOSTNAME
    HOSTNAME=${HOSTNAME:-"test"}
    
    # Disk & encryption password
    select_disk
    echo -n "Festplatten-Passwort (LUKS): "
    read -s DISK_PASS && echo ""
    DISK_PASS=${DISK_PASS:-"test"}
    
    # Git Setup
    PROVIDER=$(select_option "Git-Provider wählen" "GitHub" "GitLab" "Bitbucket")
    
    case $PROVIDER in
        GitHub)  DEF_GIT="silas-joekel"; BASE_URL="github.com" ;;
        GitLab)  DEF_GIT=$OS_USER; BASE_URL="gitlab.com" ;;
        *)       DEF_GIT=$OS_USER; BASE_URL="bitbucket.org" ;;
    esac
    
    read -p "$PROVIDER Username [$DEF_GIT]: " GIT_USER
    GIT_USER=${GIT_USER:-$DEF_GIT}
    REPO_NAME="nixos-config-$HOSTNAME"
    REPO_URL="git@$BASE_URL:$GIT_USER/$REPO_NAME.git"
    
    DEFAULT_GIT_EMAIL="silas@joekel.info"
    read -p "Git E-Mail für Commits [$DEFAULT_GIT_EMAIL]: " GIT_EMAIL
    GIT_EMAIL=${GIT_EMAIL:-$DEFAULT_GIT_EMAIL}

    read -p "Git Full Name (für Commits) [Silas Jökel]: " GIT_FULLNAME
    GIT_FULLNAME=${GIT_FULLNAME:-Silas Jökel}
}

select_disk() {
    # 1. Wir holen NAME und SIZE, filtern loop und sr (CD-ROM/ISO), 
    # und kombinieren sie pro Zeile (z.B. "sda 31G")
    mapfile -t DISKS < <(lsblk -dno NAME,SIZE,TYPE | grep "disk" | awk '{print $1 " (" $2 ")"}')

    if [ ${#DISKS[@]} -eq 0 ]; then
        echo "❌ Keine Festplatte gefunden!"
        exit 1
    elif [ ${#DISKS[@]} -eq 1 ]; then
        # Nur eine Disk? Direkt nehmen und Klammern/Größe entfernen
        DISK=$(echo "${DISKS[0]}" | awk '{print $1}')
        echo "Nur eine Festplatte gefunden: /dev/$DISK"
    else
        # Auswahl via fzf
        DISK_INFO=$(printf "%s\n" "${DISKS[@]}" | fzf --height 20% --prompt="Ziel-Festplatte wählen: " --layout=reverse)
        # Extrahiere nur den Namen (vor dem ersten Leerzeichen)
        DISK=$(echo "$DISK_INFO" | awk '{print $1}')
    fi

    # Validierung: Falls fzf abgebrochen wurde
    if [ -z "$DISK" ]; then
        echo "Abgebrochen."
        exit 1
    fi
}

print_summary() {
    echo -e "\n\n📝 ZUSAMMENFASSUNG:"
    echo "----------------------------------------------------"
    echo "-- OS ----------------------------------------------"
    echo "User: $OS_USER"
    echo "Hostname: $HOSTNAME"
    echo "----------------------------------------------------"
    echo "-- DISK --------------------------------------------"
    echo "Festplatte: /dev/$DISK"
    echo "Festplatten-Password: $DISK_PASS"
    echo "----------------------------------------------------"
    echo "-- Git ---------------------------------------------"
    echo "Provider: $PROVIDER"
    echo "User: $GIT_USER"
    echo "Email: $GIT_EMAIL"
    echo "Name: $GIT_FULLNAME"
    echo "Repository: $REPO_NAME"
    echo "Repo URL: $REPO_URL"
    echo "----------------------------------------------------"
    echo -e "\n"
}

setup_ssh() {
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$OS_USER@$HOSTNAME"
    PUBKEY=$(cat ~/.ssh/id_ed25519.pub)
    echo -e "\nSSH-KEY:\n\033[1;32m$PUBKEY\033[0m\n"
}

setup_git() {
    PROVIDER="GitHub"
    HOSTNAME="test"
    BASE_URL="github.com"
    REPO_URL="git@github.com:silas-joekel/nixos-config-test.git"
    if [[ "$PROVIDER" == "GitHub" ]]; then
        BROWSER=false gh auth login --git-protocol ssh --hostname github.com --scopes write:public_key --skip-ssh-key --web
        gh ssh-key add ~/.ssh/id_ed25519.pub --title "host-$HOSTNAME"
    else
        echo -e "\nSSH-KEY:\n\033[1;32m$PUBKEY\033[0m\n"
        read -p "Hinterlege den Key bei $PROVIDER und drücke ENTER zum Testen..."
    fi

    while ! ssh -i ~/.ssh/id_ed25519 -T -o ConnectTimeout=5 -o StrictHostKeyChecking=no git@$BASE_URL 2>&1 | grep -q "successfully authenticated"; do
        echo "⌛ Warte auf Authentifizierung bei $REPO_URL... (Retry in 5s)"
        sleep 5
    done
    echo "✅ Zugriff gewährt!"

    # Git lokal für die ISO-Session konfigurieren
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name "$GIT_FULLNAME"
    git config --global init.defaultBranch main
}

format_disk() {
    echo "🏗️ Partitioniere /dev/$DISK..."
    echo "$DISK_PASS" > /tmp/disko_pass
    sudo disko --mode zap_create_mount --argstr device "/dev/$DISK" --argstr password "/tmp/disko_pass" /etc/nixos/templates/disko-config.nix
}

setup_nix() {
    # Hardware-Config generieren
    echo "🔍 Erkenne Hardware-Spezifikationen..."
    nixos-generate-config --no-filesystems --root /mnt --dir /tmp

    # Try loading existing git repo for host
    if ! git clone "$REPO_URL" "/tmp/$REPO_NAME"; then
    	echo "Repo for host $HOST not found."
    	mkdir -p /tmp/$REPO_NAME
    	cp /etc/nixos/templates/host-flake.nix /tmp/$REPO_NAME/flake.nix
        sed -i "s/__HOSTNAME__/$HOSTNAME/g" /tmp/$REPO_NAME/flake.nix
        
        git init "/tmp/$REPO_NAME"
        git -C "/tmp/$REPO_NAME" add .
        git -C "/tmp/$REPO_NAME" commit -m "Initial setup for $HOSTNAME with nix-core modules"
        echo "Creating private GitHub repository..."
        gh repo create "$REPO_NAME" --private --source=/tmp/$REPO_NAME --remote=origin --push
    else
    	echo "Repo $REPO_NAME has been cloned successfully."
    fi

    mv /tmp/hardware-configuration.nix /tmp/$REPO_NAME/hardware-configuration.nix
    
    git -C "/tmp/$REPO_NAME" add .
    git -C "/tmp/$REPO_NAME" commit -m "Update hardware-configuration.nix for host '$HOST'"
    git -C "/tmp/$REPO_NAME" push
}

install_nix() {
    echo "🚀 Starte finale Installation von NixOS ..."
    sudo nixos-install --flake "/tmp/$REPO_NAME#$HOSTNAME"
}

confirm_install() {
    read -p "Installation jetzt starten? (Y/n): " CONFIRM
    CONFIRM=${CONFIRM:-"y"}
}

setup() {
    check_network
    collect_inputs
    print_summary
    setup_ssh
    setup_git
}

install() {
    confirm_install
    if [ "$CONFIRM" == "y" ]; then
    	echo "Installation wird gestartet ..."
    	format_disk
    	setup_nix
    	install_nix
        echo "Installation beendet!"
    else
        echo "Installation abgebrochen!"
    fi
}

main() {
    setup
    install
}

main

