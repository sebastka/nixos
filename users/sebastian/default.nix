{
  pkgs,
  config,
  lib,
  self,
  ...
}:

{
  # Desktops only: tern.nix and work.nix apply themselves only with a desktop (a NixOS import can't depend on the
  # configuration)
  imports = [
    ./tern.nix
    ./work.nix
  ];

  sops.secrets."sebastian-password".neededForUsers = true;

  users.users."sebastian" = {
    isNormalUser = true;
    description = "Sebastian Karlsen";
    extraGroups = [ "wheel" ] ++ lib.optional config.services.xserver.enable "networkmanager";
    shell = pkgs.zsh;
    # Personal Yubikey's OpenPGP authentication subkey (used through gpg-agent, see modules/nixos/desktop/gnupg.nix)
    openssh.authorizedKeys.keyFiles = [ ./keys/private.id_ed25519_gpg.pub ];
    hashedPasswordFile = config.sops.secrets."sebastian-password".path;
    email = "sebastian@karlsen.fr"; # And picture (WebFinger), on desktops: modules/nixos/common/user-email.nix
  };

  home-manager.users.sebastian = {
    imports = [ ./home.nix ] ++ lib.optional config.services.xserver.enable ./desktop.nix;
  };
}
