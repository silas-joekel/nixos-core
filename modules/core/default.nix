{ config, pkgs, lib, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true; # Verhindert doppelte Dateien im Store
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  options.allowedUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Liste der unfreien Pakete, die erlaubt sind";
  };
  config = {
    nixpkgs.config.allowUnfreePredicate = pkg: 
      builtins.elem (lib.getName pkg) config.allowedUnfreePackages;
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
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };
}
