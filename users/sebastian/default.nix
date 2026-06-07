{ pkgs, config, lib, ... }:

let
  hostFile = ./hosts/${config.networking.hostName}.nix;
in
{
  sops.secrets."sebastian-password".neededForUsers = true;

  users.users."sebastian" = {
    isNormalUser = true;
    description = "Sebastian Karlsen";
    extraGroups = [ "wheel" ] ++ lib.optional config.services.xserver.enable "networkmanager";
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets."sebastian-password".path;
  };

  home-manager.users.sebastian = {
    imports =
      [ ./home.nix ]
      ++ lib.optional config.services.xserver.enable ./desktop.nix
      ++ lib.optional (builtins.pathExists hostFile) hostFile;
  };
}
