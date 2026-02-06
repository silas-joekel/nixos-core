{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    vscode
  ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
  ];
}
