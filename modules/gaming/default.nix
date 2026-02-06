{ pkgs, lib, ... }:

{
  # Spotify
  environment.systemPackages = with pkgs; [
    discord
    mangohud
    protonup-qt
  ];
  
  allowedUnfreePackages = [
    "steam"
    "steam-unwrapped"
    "discord"
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Port for Steam Remote Play
    dedicatedServer.openFirewall = true; # Port for dedicated server
  };
}
