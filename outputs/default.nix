{
  self,
  nixpkgs,
  nixos-hardware,
  home-manager,
  ...
} @ inputs : {
nixosConfigurations = {
  fjordmail-xps15 = let
    username = "sebastian";
    specialArgs = { inherit username; };
  in
    nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = "x86_64-linux";

      modules = [
        nixos-hardware.nixosModules.dell-xps-15-7590
        nixos-hardware.nixosModules.dell-xps-15-7590-nvidia
        ../hosts/fjordmail-xps15
        ../users/${username}/nixos.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = inputs // specialArgs;
          home-manager.users.${username} = import ../users/${username}/home.nix;
        }
      ];
    };

  hermes = let
    username = "sebastian";
    specialArgs = {inherit username;};
  in
    nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = "aarch64-linux";

      modules = [
        nixos-hardware.nixosModules.raspberry-pi-4
        ../hosts/hermes
        ../users/${username}/nixos.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = inputs // specialArgs;
          home-manager.users.${username} = import ../users/${username}/home.nix;
        }
      ];
    };
  };
}
