{
  description = "NixOS Konfiguration für den Host: __HOSTNAME__";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-core.url = "github:silas-joekel/nixos-core";
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
        # nixos-core.nixosModules.gaming
        # nixos-core.nixosModule.web-dev
      ];
    };
  };
}

