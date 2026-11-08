# sebastian on desktops: everything desktop-only, from here. NixOS module (./tern.nix and ./work.nix declare secrets).
{
  config,
  lib,
  pkgs,
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
    ./nfs.nix
  ];

  # On desktops: set by every desktop environment (modules/nixos/plasma, gnome, cinnamon), not by servers
  config = lib.mkIf config.services.graphical-desktop.enable {
    users.users.sebastian.extraGroups = [ "networkmanager" ];

    # Syncthing (modules/nixos/desktop/syncthing.nix): ~/Documents, ~/Dev and Claude Code's sessions, synced between the
    # desktops through the homelab's server
    services.syncthing = {
      enable = true;
      user = "sebastian";
      group = "users";
      dataDir = config.users.users.sebastian.home;
      settings.folders = {
        Documents = {
          id = "documents";
          path = "~/Documents";
        };
        Dev = {
          id = "dev";
          path = "~/Dev";
        };
        ClaudeProjects = {
          id = "claude-projects";
          path = "~/.config/claude/projects";
        };
        ClaudeFileHistory = {
          id = "claude-file-history";
          path = "~/.config/claude/file-history";
        };
      };
    };

    # Claude Code's instructions (CLAUDE.md, below)
    sops.secrets.claude-md = {
      sopsFile = ../../secrets/desktop.sops.yaml;
      owner = "sebastian";
    };

    # mcp-nixos's key (below): one per client, X-API-Key (sebastka/homelab: k8s/applications/utils/mcp-nixos)
    sops.secrets.mcp-nixos-key = {
      sopsFile = ../../secrets/desktop.sops.yaml;
      owner = "sebastian";
    };

    home-manager.users.sebastian =
      { config, lib, ... }: # home-manager's lib (lib.hm)
      {
        # mcp-nixos (NixOS, home-manager and nix-darwin options and packages, package version history), run in the
        # homelab, for the coding agents (modules/home/programs/coding-agents). Its key from the session's environment,
        # graphical apps included: readable by sebastian anyway (the secret's file).
        programs.mcp.servers.nixos = {
          type = "http";
          url = "https://mcp-nixos.karlsen.app/mcp";
          headers.x-api-key = "\${MCP_NIXOS_KEY}"; # Expanded by the agents
        };
        home.sessionVariablesExtra = ''
          export MCP_NIXOS_KEY="$(cat ${nixosConfig.sops.secrets.mcp-nixos-key.path} 2>/dev/null)"
        '';

        # Claude Code's instructions: a link to the secret (claude-md, above), not programs.claude-code.context, which
        # would copy it into the world-readable Nix store. Edit the secret, not the file. force: replaces the file the
        # former claude-md service wrote (the secret plus today's date, which Claude Code now gives itself).
        home.file."${config.programs.claude-code.configDir}/CLAUDE.md" = {
          source = config.lib.file.mkOutOfStoreSymlink nixosConfig.sops.secrets.claude-md.path;
          force = true;
        };

        # Projects: ~/Dev/Private (private), ~/Dev/Work (./work.nix)
        home.activation.createDevPrivate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.home.homeDirectory}/Dev/Private
        '';
        # This repository
        programs.zsh.shellAliases.nixos = "cd ${config.home.homeDirectory}/Dev/Private/Nix/nixos";

        # Rootless Docker (modules/nixos/desktop/docker.nix: not started by default) started at login, as
        # `systemctl --user enable` would (it can't: the unit has no [Install] section)
        xdg.configFile."systemd/user/default.target.wants/docker.service".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/systemd/user/docker.service";

        # Bitwarden CLI (bw, modules/home/programs/bw): the private account (bitwarden.com), the default one
        programs.bw.accounts.karlsenfr.server = "https://vault.bitwarden.com";
        programs.bw.defaultAccount = "karlsenfr";

        # Bitwarden Secrets Manager (bws, modules/home/programs/bws)
        # programs.bws.profiles.karlsenfr.server_base = "https://vault.bitwarden.com";

        # CrowdSec CLI (cscli, modules/home/programs/cscli): its local API's credentials in
        # ~/.config/crowdsec/karlsenfr/local_api_credentials.yaml
        programs.cscli.profiles.karlsenfr = { };

        # Private accounts in ~/Dev/Private:
        programs.direnv.directoryEnv."Dev/Private" = {
          BITWARDENCLI_APPDATA_DIR = config.programs.bw.accounts.karlsenfr.dataDir;
          # BWS_PROFILE = "karlsenfr";
          # BWS_ACCESS_TOKEN.command = "${pkgs.libsecret}/bin/secret-tool lookup service bws account karlsenfr";
          DIGITALOCEAN_CONTEXT = "karlsenfr";
          KUBECONFIG = "${config.xdg.configHome}/kube/talmox/config.yaml";
          ARGOCD_OPTS = "--core --config ${config.xdg.cacheHome}/argocd/karlsenfr.yaml";
          CSCLI_CONFIG = config.programs.cscli.profiles.karlsenfr.configFile;
        };

        # Env vars
        home.sessionVariables.BROWSER = "firefox";
        # home.sessionVariables.BITWARDENCLI_APPDATA_DIR = "" # Set by programs.bw.defaultAccount
        # home.sessionVariables.BWS_PROFILE = "karlsenfr"; # No private bws
        # home.sessionVariables.BWS_ACCESS_TOKEN = ""; # No private bws
        home.sessionVariables.DIGITALOCEAN_CONTEXT = "karlsenfr";
        # home.sessionVariables.KUBECONFIG = "${config.xdg.configHome}/kube/talmox/config.yaml"; # Leave .config/kube/config.yaml as default
        home.sessionVariables.ARGOCD_OPTS = "--core --config ${config.xdg.cacheHome}/argocd/karlsenfr.yaml";
        home.sessionVariables.CSCLI_CONFIG = config.programs.cscli.profiles.karlsenfr.configFile;

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
