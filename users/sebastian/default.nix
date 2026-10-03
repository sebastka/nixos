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
    # Yubikey-backed (FIDO2) key, see ~/.ssh/key/private.id_ed25519_sk_rk
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMf9bldc1/uS+kAo4WGX1CW6ex0ewLP0P1v+9/+QItJcAAAABHNzaDo= sebastian@karlsen.fr"
    ];
    hashedPasswordFile = config.sops.secrets."sebastian-password".path;
  };

  home-manager.users.sebastian = {
    imports =
      [ ./home.nix ]
      ++ lib.optional config.services.xserver.enable ./desktop.nix
      ++ lib.optional (builtins.pathExists hostFile) hostFile;
  };
}
