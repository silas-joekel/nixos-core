{ pkgs, ... }:

{
  # 1. Automatischer Login für den Live-User "nixos"
  services.getty.autologinUser = "nixos";

  # 2. Bereitstellung der Templates innerhalb der ISO
  # Wir kopieren die Dateien aus deinem Core-Repo direkt in das Dateisystem der ISO
  environment.etc = {
    "nixos/templates/disko-config.nix".source = ./templates/disko-config.nix;
    "nixos/templates/host-flake.nix".source = ./templates/host-flake.nix;
  };

  # 3. Das Installations-Script als System-Package registrieren
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "setup-laptop" (builtins.readFile ./setup.sh))
  ];

  # 4. Automatischer Start des Scripts beim Öffnen der Shell
  # Wir prüfen, ob wir auf TTY1 (dem Standard-Monitor) sind, um Endlosschleifen zu vermeiden
  programs.bash.interactiveShellInit = ''
    if [[ $(tty) == "/dev/tty1" ]]; then
      echo "------------------------------------------"
      echo "Willkommen zum NixOS Zero-Touch Installer!"
      echo "------------------------------------------"
      setup-laptop
    fi
  '';

  # 5. Hilfreiche Voreinstellungen für die ISO-Umgebung
  networking.networkmanager.enable = true; # Erlaubt nmtui Nutzung
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Tastaturlayout in der ISO (vorerst Deutsch)
  console.keyMap = "de";
}

