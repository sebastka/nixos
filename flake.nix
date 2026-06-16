{
  description = "Sebastian's NixOS configuration";

  # To do:
  # - Set up secure boot with lanzaboote

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      home-manager,
      sops-nix,
      nixos-apple-silicon,
      impermanence,
    }:
    let
      mkPkgsUnstable =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      # Dell XPS 15 7590 (2020)
      nixosConfigurations.geras = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            self
            nixos-hardware
            home-manager
            sops-nix
            impermanence
            ;
          pkgs-unstable = mkPkgsUnstable "x86_64-linux";
        };
        modules = [
          ./hosts/geras
          ./users/sebastian
        ];
      };

      # Raspberry Pi 4 Model b Rev 1.4 (2020)
      nixosConfigurations.hermes = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            self
            nixos-hardware
            home-manager
            sops-nix
            ;
        };
        modules = [
          ./hosts/hermes
          ./users/sebastian
        ];
      };

      # MacBook Pro j314sap (2021) - NixOS on Asahi
      nixosConfigurations.boreas = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            self
            home-manager
            sops-nix
            nixos-apple-silicon
            ;
          pkgs-unstable = mkPkgsUnstable "aarch64-linux";
        };
        modules = [
          ./hosts/boreas
          ./users/sebastian
        ];
      };
    };
}
