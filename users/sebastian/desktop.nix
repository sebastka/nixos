{ config, lib, pkgs, osConfig, ... }:

let
  bitwarden-cli = pkgs.callPackage ../../pkgs/bitwarden-cli { };

  # Bitwarden password manager accounts: one bw data directory each.
  # Selecting an account in a project's .envrc: see README.md.
  # server = null: Bitwarden's default server (bitwarden.com).
  bitwardenProfiles = {
    private = { server = null; };
    inboxcom = { server = "https://vault.bitwarden.eu"; };
  };
  bwDataDir = name: "${config.xdg.dataHome}/bitwarden-cli/${name}";

  # Personal scripts (./scripts/<name>.sh), checked by shellcheck at build time
  scripts = map (
    name:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.kubectl ];
      text = builtins.readFile ./scripts/${name}.sh;
    }
  ) [ "to_paperless" "to_deluge" ];
in
{
  imports = [
    ../../modules/home/programs/coding-agents
    ../../modules/home/programs/ops
    ../../modules/home/programs/vscode
    ./web-apps.nix
  ];

  home.packages =
    with pkgs;
    [
      kdePackages.kate
      thunderbird
      chromium
    ]
    ++ lib.optional discord.meta.available discord # x86_64 only: not on boreas (aarch64)
    ++ scripts;

  # Browser opened by command-line tools (gh, git web--browse, Python's webbrowser...)
  home.sessionVariables.BROWSER = "firefox";

  # No Flatpak: stop Plasma Browser Integration from writing its host into ~/.var/app/<browser> of known
  # Flatpak browsers at every login. kded6rc stays writable (kded keeps its own state there).
  home.activation.noFlatpakBrowserIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kded6rc \
      --group Module-browserintegrationflatpakintegrator --key autoload --type bool false
  '';

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

  # Work (inboxcom) SSH hosts and their keys: secrets/ssh-work.sops.yaml (users/sebastian/default.nix)
  home.file.".ssh/config.d/work.conf".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets."ssh-work-config".path;
  home.file.".ssh/known_hosts.d/inboxcom".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets."ssh-work-known-hosts".path;

  # Bitwarden Secrets Manager (bws): inboxcom account only, selected with BWS_CONFIG_FILE (see README.md).
  # Its config is a secret (secrets/desktop.sops.yaml), decrypted by sops-nix (users/sebastian/default.nix)
  # and linked from outside the Nix store.
  xdg.configFile."bws/inboxcom.config".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.sops.secrets."bws-inboxcom-config".path;
}
