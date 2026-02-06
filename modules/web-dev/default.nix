{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vscode
  ];
  allowedUnfreePackages = [ "vscode" ];
}
