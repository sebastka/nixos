{ config, lib, pkgs, ... }:

let
  bitwarden-cli = pkgs.callPackage ../../pkgs/bitwarden-cli { };

  # Bitwarden accounts: one bw data directory and one bws config file each.
  # Selecting an account in a project's .envrc: see README.md.
  # server = null: Bitwarden's default server (bitwarden.com).
  bitwardenProfiles = {
    private = { server = null; };
    inboxcom = { server = "https://vault.bitwarden.eu"; };
  };
  bwDataDir = name: "${config.xdg.dataHome}/bitwarden-cli/${name}";
in
{
  imports = [
    ../../modules/home/programs/ops
    ../../modules/home/programs/vscode
  ];

  home.packages = with pkgs; [
    kdePackages.kate
    thunderbird
    bitwarden-desktop
  ];

  # Bitwarden CLI (bw): the private account by default. For the other one, e.g. in a project's .envrc:
  #   export BITWARDENCLI_APPDATA_DIR="$XDG_DATA_HOME/bitwarden-cli/inboxcom"
  home.sessionVariables.BITWARDENCLI_APPDATA_DIR = bwDataDir "private";

  # bw keeps its server URL in its data file (with the login session), which it rewrites itself:
  # set the server once, only when the account's data directory doesn't exist yet.
  home.activation.bitwardenCliProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatStrings (
      lib.mapAttrsToList (
        name: profile:
        lib.optionalString (profile.server != null) ''
          if [ ! -e "${bwDataDir name}/data.json" ]; then
            BITWARDENCLI_APPDATA_DIR="${bwDataDir name}" run ${lib.getExe bitwarden-cli} config server "${profile.server}" > /dev/null 2>&1
          fi
        ''
      ) bitwardenProfiles
    )
  );

  # Bitwarden Secrets Manager (bws): one config file per account, selected with BWS_CONFIG_FILE, e.g.
  #   export BWS_CONFIG_FILE="$XDG_CONFIG_HOME/bws/inboxcom.config"
  # The access token comes from BWS_ACCESS_TOKEN, never from these files.
  xdg.configFile = lib.mapAttrs' (
    name: profile:
    lib.nameValuePair "bws/${name}.config" {
      text = lib.concatLines (
        [ "[profiles.default]" ]
        ++ lib.optional (profile.server != null) ''server_base = "${profile.server}"''
        ++ [ ''state_dir = "${config.xdg.stateHome}/bws/${name}"'' ]
      );
    }
  ) bitwardenProfiles;
}
