{
  config,
  lib,
  pkgs,
  ...
}:

# Bitwarden Secrets Manager (bws, installed by modules/home/programs/ops): its config file, for every user. bws picks a
# profile by BWS_PROFILE, else by the access token's ID. The token is never here.
#
#   programs.bws.profiles.work.server_base = "https://vault.bitwarden.eu";
let
  cfg = config.programs.bws;
  stateDir = "${config.xdg.stateHome}/bws";
in
{
  options.programs.bws.profiles = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        freeformType = (pkgs.formats.toml { }).type; # server_base, server_api, server_identity, state_opt_out...
        options.state_dir = lib.mkOption {
          type = lib.types.str;
          default = stateDir;
          description = "Directory of the profile's login cache (one file per access token).";
        };
      }
    );
    default = { };
    description = "bws profiles, by name.";
  };

  config = {
    # Always there (with [profiles] at least): bws refuses to run when BWS_CONFIG_FILE is missing or empty
    home.sessionVariables.BWS_CONFIG_FILE = "${config.xdg.configHome}/bws/config.toml";
    xdg.configFile."bws/config.toml".source = (pkgs.formats.toml { }).generate "bws-config.toml" {
      inherit (cfg) profiles;
    };

    # bws writes the login cache readable by all: its directory is private. Without a profile, bws still uses
    # ~/.config/bws/state (no setting for it).
    home.activation.bwsStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run install -d -m 700 ${stateDir}
    '';
  };
}
