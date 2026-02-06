{ pkgs, lib, ... }:

{
  # Explicitly define unfree packages
  allowedUnfreePackages = [
    "google-chrome"
    "spotify"
  ];

  environment.systemPackages = with pkgs; [
    google-chrome
    spotify
  ];

  # Spotify specific additions
  networking.firewall.allowedTCPPorts = [ 57621 ]; # sync with mobile devices in the same network
  networking.firewall.allowedUDPPorts = [ 5353 ]; # to enable Spotify Connect, e.g. Google Cast devices
}
