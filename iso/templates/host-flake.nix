{
  description = "NixOS Konfiguration für den Host: __HOSTNAME__";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Dein öffentliches Core-Repo als Basis
    nixos-core.url = "github:silas-joekel/nixos-core";
  };

  outputs = { self, nixpkgs, nixos-core, ... }@inputs: {
    nixosConfigurations."__HOSTNAME__" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware-configuration.nix
        # Hier bindest du die Module aus deinem öffentlichen Repo ein
        nixos-core.nixosModules.core
        # nixos-core.nixosModules.gaming
        # nixos-core.nixosModule.web-dev
      ];
    };
  };
}

