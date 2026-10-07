{
  config,
  lib,
  pkgs,
  ...
}:

# Bitwarden CLI (bw, installed by modules/home/programs/ops): one data directory per account, for every user. bw keeps
# everything there (data.json: server, login, cached vault), so BITWARDENCLI_APPDATA_DIR selects the account.
#
#   programs.bw.accounts.work.server = "https://vault.bitwarden.eu";
#   programs.bw.defaultAccount = "work";
#   programs.direnv.directoryEnv."Dev/Work".BITWARDENCLI_APPDATA_DIR = config.programs.bw.accounts.work.dataDir;
let
  cfg = config.programs.bw;
  bitwarden-cli = pkgs.callPackage ../../../../pkgs/bitwarden-cli { };
  stateDir = "${config.xdg.stateHome}/bitwarden-cli";
in
{
  options.programs.bw = {
    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              server = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "https://vault.bitwarden.eu";
                description = "The account's server (null: bw's default, bitwarden.com).";
              };
              dataDir = lib.mkOption {
                type = lib.types.str;
                default = "${stateDir}/${name}";
                description = "The account's data directory (BITWARDENCLI_APPDATA_DIR).";
              };
            };
          }
        )
      );
      default = { };
      description = "bw accounts, by name.";
    };
    defaultAccount = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Account used outside directories selecting another one (null: an unnamed one).";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.defaultAccount == null || cfg.accounts ? ${cfg.defaultAccount};
        message = "programs.bw.defaultAccount: ${toString cfg.defaultAccount} is not in programs.bw.accounts";
      }
    ];

    # Instead of ~/.config/Bitwarden CLI
    home.sessionVariables.BITWARDENCLI_APPDATA_DIR =
      if cfg.defaultAccount == null then
        "${stateDir}/default"
      else
        cfg.accounts.${cfg.defaultAccount}.dataDir;

    # Private directories (logins). bw keeps its server in data.json, which it rewrites itself (and won't change while
    # logged in): set once, only when the account has no data yet.
    home.activation.bwAccounts = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      ''
        run install -d -m 700 ${stateDir}
      ''
      + lib.concatMapStrings (
        account:
        ''
          run install -d -m 700 ${lib.escapeShellArg account.dataDir}
        ''
        + lib.optionalString (account.server != null) ''
          if [ ! -e ${lib.escapeShellArg "${account.dataDir}/data.json"} ]; then
            BITWARDENCLI_APPDATA_DIR=${lib.escapeShellArg account.dataDir} run ${lib.getExe bitwarden-cli} config server ${lib.escapeShellArg account.server} > /dev/null 2>&1
          fi
        ''
      ) (lib.attrValues cfg.accounts)
    );
  };
}
