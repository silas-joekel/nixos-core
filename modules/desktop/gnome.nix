{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    
    xkb.layout = "de";
  };
  
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # Exklusive GNOME-Pakete
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome.gnome-extensions-app
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];
  
  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
