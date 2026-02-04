{
  description = "Public Core NixOS Configuration & Installer ISO";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Tool zum einfachen Erstellen von ISOs
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-Optimierungen (optional, aber empfohlen)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-generators, ... }@inputs: {
    
    # 1. Export der Module (für die Nutzung in Host-Repos)
    nixosModules = {
      core = import ./modules/core;
      web-dev = import ./modules/web-dev;
      gaming = import ./modules/gaming;
      
      default = { ... }: {
        imports = [ ./modules/core ];
        _module.args.inputs = inputs; 
      };
    };

    # 2. Definition der Custom ISO
    # Bauen mit: nix build .#installer
    packages.x86_64-linux.installer = nixos-generators.nixosGenerate {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      format = "install-iso"; # Hier definierst du das Format
      
      specialArgs = { inherit inputs; };
      
      modules = [
        # WICHTIG: Die Standard-ISO-Basis wird hier oft automatisch gesetzt, 
        # aber wir können sie zur Sicherheit explizit einbinden:
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        
        ./modules/core
        ./iso/default.nix
        
        ({ pkgs, ... }: {
          environment.systemPackages = [
            pkgs.git
            pkgs.fzf
            pkgs.gh
            pkgs.disko
          ];
        })
      ];
    };
  };
}
