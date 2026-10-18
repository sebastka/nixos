{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
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
    ];
    # In Zed's PATH: the Nix extension's language server (it downloads none, unlike Zed's other languages)
    extraPackages = [ pkgs.nixd ];

    # Merged into ~/.config/zed/settings.json at each switch, these keys winning: Zed can still save its own changes
    # (the theme picker, an agent added...), kept unless set here (mutableUserSettings, the default).
    userSettings = {
      # The agents of the Agent Panel (ACP), from Zed's registry
      agent_servers = {
        github-copilot-cli.type = "registry";
        claude-acp.type = "registry";
      };

      theme = {
        mode = "dark";
        light = "One Light";
        dark = "One Dark";
      };
      icon_theme = "Zed (Default)";
      ui_font_size = 16;
      buffer_font_size = 15;

      # The project tree on the left (Zed's default: the right)
      project_panel.dock = "left";

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
