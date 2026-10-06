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
      { config, ... }:
      {
        # Browser opened by command-line tools (gh, git web--browse, Python's webbrowser...)
        home.sessionVariables.BROWSER = "firefox";

        # Bitwarden CLI (bw): one data directory per account, the private one (bitwarden.com) by default. The inboxcom
        # one (./work.nix), e.g. in a project's .envrc (see README.md):
        #   export BITWARDENCLI_APPDATA_DIR="$XDG_DATA_HOME/bitwarden-cli/inboxcom"
        home.sessionVariables.BITWARDENCLI_APPDATA_DIR = "${config.xdg.dataHome}/bitwarden-cli/private";

        # Web apps (modules/home/programs/web-apps); the work ones: ./work.nix
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
