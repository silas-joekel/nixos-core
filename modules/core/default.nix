{ pkgs, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true; # Verhindert doppelte Dateien im Store
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.networkmanager.enable = true;
  
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    pciutils
    usbutils
  ];
  
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # Nur SSH-Keys für maximale Sicherheit
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
}
