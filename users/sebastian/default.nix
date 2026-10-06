{ pkgs, config, ... }:

{
  imports = [ ./desktop.nix ]; # Desktop-only parts, Tern and work included

  sops.secrets."sebastian-password".neededForUsers = true;

  users.users."sebastian" = {
    isNormalUser = true;
    description = "Sebastian Karlsen";
    extraGroups = [ "wheel" ]; # On desktops also networkmanager (./desktop.nix)
    shell = pkgs.zsh;
    # Personal Yubikey's OpenPGP authentication subkey (used through gpg-agent, see modules/nixos/desktop/gnupg.nix)
    openssh.authorizedKeys.keyFiles = [ ./keys/private.id_ed25519_gpg.pub ];
    hashedPasswordFile = config.sops.secrets."sebastian-password".path;
    email = "sebastian@karlsen.fr"; # And picture (WebFinger), on desktops: modules/nixos/common/user-email.nix
  };

  home-manager.users.sebastian = {
    imports = [ ./home.nix ]; # Every host (desktops: ./desktop.nix)
  };
}
