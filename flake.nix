{
  description = "sebastka's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    #nix-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    #nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # impermanence.url = "github:nix-community/impermanence";

    # nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = inputs: import ./outputs inputs;
}
