{
  description = "Sebastian's NixOS configuration";

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
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tern = {
      url = "github:sebastka/tern";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      disko,
      lanzaboote,
      tern,
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
      # Packages from pkgs/, for both systems: used as `nix flake check` checks
      # (CI builds them natively on x86_64 and aarch64)
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        nixpkgs.lib.mapAttrs (
          name: _: nixpkgs.legacyPackages.${system}.callPackage ./pkgs/${name} { }
        ) (builtins.readDir ./pkgs)
      );
      checks = self.packages;

      # Tools to work on this repo, loaded by direnv (.envrc) and used by CI (`nix develop -c ...`).
      # GnuPG comes from the host (configured gpg-agent and pinentry).
      devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              sops       # Secrets (secrets/*.sops.yaml)
              ssh-to-age # Host SSH key -> age recipient (.sops.yaml)
              sbctl      # Secure Boot keys (secrets/*-secure-boot.sops.yaml)
              nixfmt
              shellcheck
              yamllint
            ];
          };
        }
      );

      # Dell XPS 15 7590 (2020)
      nixosConfigurations.geras = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            self
            nixos-hardware
            home-manager
            sops-nix
            impermanence
            disko
            lanzaboote
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
