{ pkgs, lib, ... }:

{
  # Spotify
  environment.systemPackages = with pkgs; [
    spotify
  ];
  allowedUnfreePackages = [ "spotify" ];
  networking.firewall.allowedTCPPorts = [ 57621 ]; # sync with mobile devices in the same network
  networking.firewall.allowedUDPPorts = [ 5353 ]; # to enable Spotify Connect, e.g. Google Cast devices
}
