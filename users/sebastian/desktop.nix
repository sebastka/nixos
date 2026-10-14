# sebastian on desktops: everything desktop-only, from here. NixOS module (./tern.nix and ./work.nix declare secrets).
{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  nixosConfig = config;
in

{
  # They apply themselves only with a desktop too: a NixOS import can't depend on the configuration
  imports = [
    # ./tern.nix # Disabled (as modules/nixos/desktop/tern.nix)
    ./work.nix
  ];

  config = lib.mkIf config.services.xserver.enable {
    users.users.sebastian.extraGroups = [ "networkmanager" ];

    # Claude Code's instructions (CLAUDE.md, below), without the date
    sops.secrets.claude-md = {
      sopsFile = "${self}/secrets/desktop.sops.yaml";
      owner = "sebastian";
    };

    home-manager.users.sebastian =
      { config, lib, ... }: # home-manager's lib (lib.hm)
      {
        # Claude Code's instructions: "1. Current date: YYYY-MM-DD", then the secret's (claude-md, above). Written at
        # login and each day (at midnight, or on waking after it): edit the secret, not the file.
        systemd.user.services.claude-md = {
          Unit.Description = "Claude Code's CLAUDE.md, with today's date";
          Service = {
            Type = "oneshot";
            ExecStart = lib.getExe (
              pkgs.writeShellApplication {
                name = "claude-md";
                runtimeInputs = [ pkgs.coreutils ];
                text = ''
                  dir=${lib.escapeShellArg config.programs.claude-code.configDir}
                  install -d -m 700 "$dir"
                  tmp="$(mktemp "$dir/.CLAUDE.md.XXXXXX")"
                  { echo "1. Current date: $(date +%F)"; cat ${nixosConfig.sops.secrets.claude-md.path}; } > "$tmp"
                  mv -f "$tmp" "$dir/CLAUDE.md"
                '';
              }
            );
          };
          Install.WantedBy = [ "default.target" ];
        };
        systemd.user.timers.claude-md = {
          Unit.Description = "Claude Code's CLAUDE.md, with today's date, each day";
          Timer = {
            OnCalendar = "daily";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };

        # Projects: ~/Dev/Private (private), ~/Dev/Work (./work.nix)
        home.activation.createDevPrivate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.home.homeDirectory}/Dev/Private
        '';

        # Rootless Docker (modules/nixos/desktop/docker.nix: not started by default) started at login, as
        # `systemctl --user enable` would (it can't: the unit has no [Install] section)
        xdg.configFile."systemd/user/default.target.wants/docker.service".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/systemd/user/docker.service";

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
          ARGOCD_OPTS = "--core --config ${config.xdg.cacheHome}/argocd/karlsenfr.yaml";
        };

        # Env vars
        home.sessionVariables.BROWSER = "firefox";
        # home.sessionVariables.BITWARDENCLI_APPDATA_DIR = "" # Set by programs.bw.defaultAccount
        # home.sessionVariables.BWS_PROFILE = "karlsenfr"; # No private bws
        # home.sessionVariables.BWS_ACCESS_TOKEN = ""; # No private bws
        home.sessionVariables.DIGITALOCEAN_CONTEXT = "karlsenfr";
        # home.sessionVariables.KUBECONFIG = "${config.xdg.configHome}/kube/talmox/config.yaml"; # Leave .config/kube/config.yaml as default
        home.sessionVariables.ARGOCD_OPTS = "--core --config ${config.xdg.cacheHome}/argocd/karlsenfr.yaml";

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
