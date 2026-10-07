{
  pkgs,
  pkgs-unstable,
  config,
  lib,
  ...
}:

let
  longhorn-cli = pkgs.callPackage ../../../../pkgs/longhorn-cli { };
  helm = pkgs.callPackage ../../../../pkgs/helm { };
  argocd = pkgs.callPackage ../../../../pkgs/argocd { };
  kubeseal = pkgs.callPackage ../../../../pkgs/kubeseal { };
  kube-capacity = pkgs.callPackage ../../../../pkgs/kube-capacity { };
  cilium-cli = pkgs.callPackage ../../../../pkgs/cilium-cli { };
  awscli2 = pkgs.callPackage ../../../../pkgs/awscli2 { };
  stripe-cli = pkgs.callPackage ../../../../pkgs/stripe-cli { };
  mailcore-cli = pkgs.callPackage ../../../../pkgs/mailcore-cli { };
  domeneshop-cli = pkgs.callPackage ../../../../pkgs/domeneshop-cli { };
  bitwarden-cli = pkgs.callPackage ../../../../pkgs/bitwarden-cli { };
  bws = pkgs.callPackage ../../../../pkgs/bws { };
  topf = pkgs.callPackage ../../../../pkgs/topf { };
  zitadel = pkgs.callPackage ../../../../pkgs/zitadel { };
in

{
  home.packages = [
    # Kubernetes
    pkgs-unstable.kubectl
    helm
    pkgs.k9s
    argocd
    pkgs-unstable.kustomize
    pkgs-unstable.kubecolor
    kubeseal
    kube-capacity
    pkgs.velero
    cilium-cli
    pkgs-unstable.egctl
    pkgs.talosctl
    topf
    longhorn-cli
    pkgs.cmctl
    pkgs.kyverno
    pkgs.kubectl-validate
    pkgs.kubelogin-oidc
    pkgs.hubble
    pkgs.cri-tools

    # Container images
    pkgs.skopeo # Inspect, copy and verify images in registries
    pkgs.cosign # Sign and verify images (Sigstore)

    # Infrastructure as code
    pkgs-unstable.opentofu
    pkgs-unstable.tofu-ls # Its language server (editors)

    # Configuration management
    pkgs.ansible

    # Cloud
    awscli2
    pkgs.doctl
    stripe-cli
    mailcore-cli

    # CI/CD
    pkgs.gh
    pkgs.act

    # DNS
    pkgs.drill
    pkgs.cli53
    domeneshop-cli

    # Identity
    zitadel

    # Secrets & encryption
    pkgs.sops
    pkgs.age
    bitwarden-cli # bw: Bitwarden password manager
    bws # Bitwarden Secrets Manager
  ];

  # The OpenTofu VS Code extension (modules/home/programs/vscode) runs our tofu-ls and tofu instead of its bundled
  # language server (as the coding agents' extensions, modules/home/programs/coding-agents)
  programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
    "opentofu.languageServer.path" = lib.getExe pkgs-unstable.tofu-ls;
    "opentofu.languageServer.tofu.path" = lib.getExe pkgs-unstable.opentofu;
  };

  # zsh completions not provided by the packages themselves (pkgs/ generate theirs at build time)
  programs.zsh.initContent = ''
    # `k` alias: kubecolor's completion file only registers kubectl
    compdef kubecolor=kubectl

    # tofu (`tf` alias) and aws only provide bash-style completion
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C ${lib.getExe pkgs-unstable.opentofu} tofu
    complete -C ${awscli2}/bin/aws_completer aws

    # bw can't generate its completion at build time (pkgs/bitwarden-cli): load it on first use
    _bw() { unfunction _bw; eval "$(${lib.getExe bitwarden-cli} completion --shell zsh 2>/dev/null)"; _bw "$@"; }
    compdef _bw bw
  '';

  xdg.configFile."kube/rc.yaml".text = ''
    # https://kubernetes.io/docs/reference/kubectl/kuberc/#suggested-defaults
    ---
    apiVersion: kubectl.config.k8s.io/v1beta1
    kind: Preference
    credentialPluginPolicy: Allowlist
    credentialPluginAllowlist: [{command: kubectl-oidc_login},{command: doctl}]
    defaults:
      - {command: apply,  options: [{name: server-side, default: 'true'}]}  # (1) default server-side apply
      # - {command: delete, options: [{name: interactive, default: 'true'}]}  # (2) default interactive deletion
    aliases:
      - {name: klogs, command: logs,     appendArgs: [--tail=50, --follow]}
      - {name: gn,    command: get,      appendArgs: [nodes, --output=wide]}
      - {name: dn,    command: describe, appendArgs: [nodes, --output=wide]}
      - {name: gp,    command: get,      appendArgs: [pods, --output=wide]}
      - {name: dp,    command: describe, appendArgs: [pods, --output=wide]}
      - {name: gd,    command: get,      appendArgs: [deployments, --output=wide]}
      - {name: dd,    command: describe, appendArgs: [deployments, --output=wide]}
      - {name: gs,    command: get,      appendArgs: [services, --output=wide]}
      - {name: ds,    command: describe, appendArgs: [services, --output=wide]}
  '';
}
