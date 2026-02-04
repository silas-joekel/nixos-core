#!/usr/bin/env bash
set -e

# --- HELPERS ---
select_option() {
    local prompt="$1"; shift
    printf "%s\n" "$@" | fzf --height 40% --prompt="> $prompt: "
}

# --- FUNCTIONS ---

collect_inputs() {
    # Disk & encryption password
    select_disk
    echo -n "Festplatten-Passwort (LUKS): "
    read -s DISK_PASS && echo ""
    DISK_PASS=${DISK_PASS:-"test"}
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
    echo "-- DISK --------------------------------------------"
    echo "Festplatte: /dev/$DISK"
    echo "Festplatten-Password: $DISK_PASS"
    echo "----------------------------------------------------"
    echo -e "\n"
}

format_disk() {
    echo "🏗️ Partitioniere /dev/$DISK..."
    echo "$DISK_PASS" > /tmp/disko_pass
    sudo disko --mode zap_create_mount --argstr device "/dev/$DISK" --argstr password "/tmp/disko_pass" /etc/nixos/templates/disko-config.nix
}

main() {
    collect_inputs
    print_summary
    format_disk
}

main

