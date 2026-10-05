{ pkgs, config, lib, self, ... }:

let
  hostFile = ./hosts/${config.networking.hostName}.nix;
in
{
  imports = [ ./tern.nix ]; # Desktops only

  sops.secrets = lib.mkMerge [
    { "sebastian-password".neededForUsers = true; }

    # Config files, linked under ~/.config by ./desktop.nix.
    (lib.mkIf config.services.xserver.enable (
      lib.genAttrs [ "bws-inboxcom-config" ] (_: {
        sopsFile = "${self}/secrets/desktop.sops.yaml";
        owner = "sebastian";
      })
    ))

    # Work (inboxcom) SSH hosts and their keys (company infrastructure: encrypted), linked under ~/.ssh by ./desktop.nix
    (lib.mkIf config.services.xserver.enable (
      lib.genAttrs [ "ssh-work-config" "ssh-work-known-hosts" ] (_: {
        sopsFile = "${self}/secrets/ssh-work.sops.yaml";
        owner = "sebastian";
      })
    ))
  ];

  users.users."sebastian" = {
    isNormalUser = true;
    description = "Sebastian Karlsen";
    extraGroups = [ "wheel" ] ++ lib.optional config.services.xserver.enable "networkmanager";
    shell = pkgs.zsh;
    # Personal Yubikey's PIV key (used through the agent, see modules/home/programs/ssh)
    openssh.authorizedKeys.keyFiles = [ ./keys/private.id_ed25519_piv.pub ];
    hashedPasswordFile = config.sops.secrets."sebastian-password".path;
    webfinger = "sebastian@karlsen.fr"; # Email and picture on desktops (modules/nixos/common/webfinger-accounts.nix)
  };

  home-manager.users.sebastian = {
    imports =
      [ ./home.nix ]
      ++ lib.optional config.services.xserver.enable ./desktop.nix
      ++ lib.optional (builtins.pathExists hostFile) hostFile;
  };
}
