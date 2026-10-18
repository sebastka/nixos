{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  # A theme's accent colors (theme_overrides)
  accent = color: {
    "text.accent" = color;
    "icon.accent" = color;
    "border.focused" = color;
  };

  # Ansible's own directories (playbooks, roles, inventories' variables)
  ansibleDirectories = [
    "playbooks"
    "tasks"
    "handlers"
    "defaults"
    "vars"
    "meta"
    "group_vars"
    "host_vars"
  ];
  # Kubernetes' built-in kinds, as named in files (Services.yaml, ServiceAccounts.yaml: several in one file)
  kubernetesKinds = [
    "Namespace"
    "Deployment"
    "StatefulSet"
    "DaemonSet"
    "Job"
    "CronJob"
    "Service"
    "Services"
    "ServiceAccount"
    "ServiceAccounts"
    "ConfigMap"
    "Secret"
    "PersistentVolume"
    "PersistentVolumeClaim"
    "Role"
    "RoleBinding"
    "ClusterRole"
    "ClusterRoleBinding"
    "NetworkPolicy"
    "Ingress"
    "PodDisruptionBudget"
    "HorizontalPodAutoscaler"
  ];
in
{
  # Zed (zeditor): weekly releases (stable lags months behind), from cache.nixos.org
  programs.zed-editor = {
    enable = true;
    package = pkgs-unstable.zed-editor;

    # Extensions, from Zed's registry: installed (and updated) by Zed itself (auto_install_extensions)
    extensions = [
      "nix"
      "opentofu"
      "dockerfile" # Docker Compose too
      "ansible" # Its files: file_types.Ansible below
      "helm" # Charts' templates ({{ }}), not plain YAML
      # Themes: VS Code's defaults (theme below)
      "vscode-dark-modern"
      "vscode-light-modern"
    ];
    # In Zed's PATH: the Nix extension's language server (it downloads none, unlike Zed's other languages)
    extraPackages = [ pkgs.nixd ];

    # Merged into ~/.config/zed/settings.json at each switch, these keys winning: Zed can still save its own changes
    # (the theme picker, an agent added...), kept unless set here (mutableUserSettings, the default).
    userSettings = {
      # The agents of the Agent Panel (ACP), from Zed's registry. Claude Code: ours, from Nix
      # (modules/home/programs/coding-agents).
      agent_servers.github-copilot-cli.type = "registry";

      theme = {
        mode = "dark";
        # VS Code's (Dark Modern, its default): darker than Zed's One Dark (#1F1F1F, not #282C34)
        light = "VSCode Light Modern";
        dark = "VSCode Dark Modern";
      };
      icon_theme = "Zed (Default)";
      ui_font_size = 15; # Also the project tree's (it has none of its own), tabs, menus and panels
      buffer_font_size = 14; # Code, as VS Code (its default editor.fontSize); also the terminal's

      # The project tree on the left, the Agent Panel on the right: Zed's defaults swapped
      project_panel = {
        dock = "left";
        # Denser, as VS Code's: closer rows (default "comfortable"), less indentation per level (default 20)
        entry_spacing = "standard";
        indent_size = 16;
      };
      agent = {
        dock = "right";
        # Less verbose threads: commands' output and thinking collapsed (a click expands them); edits' diffs stay open
        expand_terminal_card = false;
        thinking_display = "always_collapsed";
        # Elapsed time during a reply, and its duration afterwards
        show_turn_stats = true;
        # Shorter lines: the column centered in the panel narrower (default 850 px)
        max_content_width = 720;
      };
      # The Agent Panel's text: Claude's replies (UI font, by default its size) and your messages (buffer font, by
      # default 12)
      agent_ui_font_size = 15;
      agent_buffer_font_size = 14;

      # Claude's orange as the accent (links, accented text and icons, focused borders): everywhere in Zed, as themes
      # can't target the Agent Panel alone. Darker on the light theme, for contrast.
      theme_overrides = {
        "VSCode Dark Modern" = accent "#d97757ff";
        "VSCode Light Modern" = accent "#c15f3cff";
      };

      # Editor, as VS Code (modules/home/programs/vscode). Already Zed's defaults: tab size 4, trailing whitespace
      # trimmed and a final newline on save, no minimap.
      format_on_save = "on";
      show_whitespaces = "boundary";
      wrap_guides = [
        80
        120
      ];
      autosave = "on_focus_change";
      colorize_brackets = true;

      file_types = {
        # HuJSON (Tailscale's policy file...) as JSON with comments
        JSONC = [ "*.hujson" ];
        # Ansible: by directory, as Ansible itself (Zed can't tell a playbook from YAML), at any depth (e.g.
        # inventories/group_vars/<group>/*.yaml)
        Ansible = lib.concatMap (dir: [
          "**/${dir}/**/*.yaml"
          "**/${dir}/**/*.yml"
        ]) ansibleDirectories;
      };

      # YAML (built in, yaml-language-server). Not formatted on save: Zed's formatter (Prettier) would rewrite
      # yamllint's style ({memory: 16Mi} flow mappings, comments...). Nor Ansible's and Helm's, YAML too.
      # languages.YAML.format_on_save = "off";
      # languages.Ansible.format_on_save = "off";
      # languages.Helm.format_on_save = "off";
      # Kubernetes' schema (completion, validation) for the core kinds only, by file name: <Kind>.<name>.yaml in a
      # k8s directory (homelab repo). CRDs (Cilium, Kyverno, ArgoCD...) and kustomization.yaml (SchemaStore's own
      # schema) would fail it.
      lsp.yaml-language-server.settings.yaml.schemas.kubernetes = lib.concatMap (kind: [
        "**/k8s/**/${kind}.yaml"
        "**/k8s/**/${kind}.*.yaml"
      ]) kubernetesKinds;

      telemetry = {
        # diagnostics = false; # Crash reports
        metrics = false; # Usage data
      };

      # Nix: nixd only (completion and docs of NixOS and home-manager options), formatting with nixfmt (as VS Code)
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp.nixd.settings.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
    };
  };
}
