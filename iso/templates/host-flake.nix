{
  description = "NixOS Konfiguration für den Host: __HOSTNAME__";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-core.url = "git+ssh://git@github.com/silas-joekel/nixos-core.git";
  };

  outputs = { self, nixpkgs, nixos-core, disko, ... }@inputs: {
    nixosConfigurations."__HOSTNAME__" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        (import ./disko-config.nix { device = "/dev/__DISK__"; password = null; })
        
        ./hardware-configuration.nix
        
        nixos-core.nixosModules.core
        #nixos-core.nixosModules.gnome
        #nixos-core.nixosModules.common
        #nixos-core.nixosModules.web-dev
        #nixos-core.nixosModules.gaming
        
        ({ pkgs, ... }: {
          users.users.__USER__ = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" "video" ];
          };
          networking.hostName = "__HOSTNAME__";
        })
      ];
    };
  };
}

