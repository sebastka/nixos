# sebastian on desktops: everything desktop-only, from here. NixOS module (./tern.nix and ./work.nix declare secrets).
{ config, lib, ... }:

{
  # They apply themselves only with a desktop too: a NixOS import can't depend on the configuration
  imports = [
    # ./tern.nix # Disabled (as modules/nixos/desktop/tern.nix)
    ./work.nix
  ];

  config = lib.mkIf config.services.xserver.enable {
    users.users.sebastian.extraGroups = [ "networkmanager" ];

    home-manager.users.sebastian =
      { config, lib, ... }: # home-manager's lib (lib.hm)
      {
        # Projects: ~/Dev/Private (private), ~/Dev/Work (./work.nix)
        home.activation.createDevPrivate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.home.homeDirectory}/Dev/Private
        '';

        # Bitwarden CLI (bw, modules/home/programs/bw): the private account (bitwarden.com), the default one
        programs.bw.accounts.karlsenfr.server = "https://vault.bitwarden.com";
        programs.bw.defaultAccount = "karlsenfr";

        # Bitwarden Secrets Manager (bws, modules/home/programs/bws)
        # programs.bws.profiles.karlsenfr.server_base = "https://vault.bitwarden.com";

        # Private accounts in ~/Dev/Private:
        programs.direnv.directoryEnv."Dev/Private" = {
          BITWARDENCLI_APPDATA_DIR = config.programs.bw.accounts.karlsenfr.dataDir;
          # BWS_PROFILE = "karlsenfr";
          # BWS_ACCESS_TOKEN.command = "${pkgs.libsecret}/bin/secret-tool lookup service bws account karlsenfr";
          DIGITALOCEAN_CONTEXT = "karlsenfr";
          KUBECONFIG = "${config.xdg.configHome}/kube/talmox/config.yaml";
          ARGOCD_OPTS = "--config ${config.xdg.configHome}/argocd/karlsenfr.yaml";
        };

        # Env vars
        home.sessionVariables.BROWSER = "firefox";
        # home.sessionVariables.BITWARDENCLI_APPDATA_DIR = "" # Set by programs.bw.defaultAccount
        # home.sessionVariables.BWS_PROFILE = "karlsenfr"; # No private bws
        # home.sessionVariables.BWS_ACCESS_TOKEN = ""; # No private bws
        home.sessionVariables.DIGITALOCEAN_CONTEXT = "karlsenfr";
        # home.sessionVariables.KUBECONFIG = "${config.xdg.configHome}/kube/talmox/config.yaml"; # Leave .config/kube/config.yaml as default
        home.sessionVariables.ARGOCD_OPTS = "--config ${config.xdg.configHome}/argocd/karlsenfr.yaml";

        # Web apps (modules/home/programs/web-apps)
        programs.webApps.apps = {
          bitwarden-private = {
            name = "Bitwarden (sebastian@karlsen.fr)";
            url = "https://vault.bitwarden.com/#/vault";
            profile = "bitwarden-private-sebastian.karlsen.fr";
            icon = ./icons/bitwarden.svg;
            genericName = "Password Manager";
            comment = "Bitwarden web vault for sebastian@karlsen.fr";
          };
          discord = {
            name = "Discord";
            url = "https://discord.com/app";
            icon = ./icons/discord.svg; # From the Papirus icon theme (GPL-3.0)
            genericName = "Internet Messenger";
            comment = "All-in-one voice and text chat";
          };
        };
      };
  };
}
