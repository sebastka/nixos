# sebastian on desktops: everything desktop-only, from here. NixOS module (./tern.nix and ./work.nix declare secrets).
{ config, lib, ... }:

{
  # They apply themselves only with a desktop too: a NixOS import can't depend on the configuration
  imports = [
    ./tern.nix
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

        # Private accounts in ~/Dev/Private:
        home.file."Dev/Private/.envrc".text = ''
          export BITWARDENCLI_APPDATA_DIR="${config.xdg.dataHome}/bitwarden-cli/private"
          export DIGITALOCEAN_CONTEXT=karlsenfr
        '';
        programs.direnv.config.whitelist.exact = [ "${config.home.homeDirectory}/Dev/Private/.envrc" ];

        # Env vars
        home.sessionVariables.BROWSER = "firefox";
        home.sessionVariables.BITWARDENCLI_APPDATA_DIR = "${config.xdg.dataHome}/bitwarden-cli/private";
        home.sessionVariables.DIGITALOCEAN_CONTEXT = "karlsenfr";

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
