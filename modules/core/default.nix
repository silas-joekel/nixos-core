{ pkgs, ... }: {
  # Grundlegende System-Features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Basis-Pakete
  environment.systemPackages = with pkgs; [
    git vim wget curl cryptsetup
  ];

  # Bootloader & Encryption Vorbereitung (nur Logik, keine Hardware-IDs)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Locale
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
  
  # Dein Window-Manager (Beispiel Sway)
  programs.sway.enable = true;
  
  # Install firefox.
  programs.firefox.enable = true;

  networking.networkmanager.enable = true;
}
