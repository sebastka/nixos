{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

# CrowdSec's CLI (cscli, installed by modules/home/programs/ops): one profile per CrowdSec, for every user. Each one has
# its config (~/.config/crowdsec/<name>/config.yaml, generated), pointing at its local API's credentials beside it
# (local_api_credentials.yaml: url, login, password; never in this repository), and its hub data
# (~/.local/share/crowdsec/<name>). cscli has no variable for its config: the cscli installed adds
# `-c "$CSCLI_CONFIG"` when it's set (an explicit -c after it still wins).
#
#   programs.cscli.profiles.work = { };
#   programs.direnv.directoryEnv."Dev/Work".CSCLI_CONFIG = config.programs.cscli.profiles.work.configFile;
let
  cfg = config.programs.cscli;
  crowdsec = pkgs-unstable.crowdsec; # Its latest release
  cscli = pkgs.writeShellScript "cscli" ''
    exec ${crowdsec}/bin/cscli ''${CSCLI_CONFIG:+-c "$CSCLI_CONFIG"} "$@"
  '';
in
{
  options.programs.cscli = {
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = pkgs.symlinkJoin {
        name = "cscli-${crowdsec.version}";
        paths = [ crowdsec ];
        postBuild = ''
          rm $out/bin/cscli
          ln -s ${cscli} $out/bin/cscli
        '';
      };
      description = "CrowdSec (its zsh completion included), with cscli using CSCLI_CONFIG.";
    };
    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              configDir = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = "${config.xdg.configHome}/crowdsec/${name}";
                description = "The profile's directory: config.yaml, and local_api_credentials.yaml (yours).";
              };
              configFile = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = "${config.xdg.configHome}/crowdsec/${name}/config.yaml";
                description = "The profile's config (CSCLI_CONFIG).";
              };
              dataDir = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = "${config.xdg.dataHome}/crowdsec/${name}";
                description = "The profile's hub data.";
              };
            };
          }
        )
      );
      default = { };
      description = "cscli profiles, by name.";
    };
  };

  config = lib.mkIf (cfg.profiles != { }) {
    xdg.configFile = lib.mapAttrs' (
      name: profile:
      lib.nameValuePair "crowdsec/${name}/config.yaml" {
        text = lib.generators.toYAML { } {
          common.log_media = "stdout";
          config_paths = {
            config_dir = profile.configDir;
            data_dir = profile.dataDir;
            hub_dir = "${profile.dataDir}/hub";
            index_path = "${profile.dataDir}/hub/.index.json";
          };
          api.client.credentials_path = "${profile.configDir}/local_api_credentials.yaml";
        };
      }
    ) cfg.profiles;

    # Private directories (credentials), and the hub's (cscli doesn't create it)
    home.activation.cscliProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatMapStrings (profile: ''
        run install -d -m 700 ${lib.escapeShellArg profile.configDir} ${lib.escapeShellArg "${profile.dataDir}/hub"}
      '') (lib.attrValues cfg.profiles)
    );
  };
}
