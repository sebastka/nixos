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
  bitwarden-cli = pkgs.callPackage ../../../../pkgs/bitwarden-cli { };
  bws = pkgs.callPackage ../../../../pkgs/bws { };
in

{
  home.packages = [
    # Kubernetes
    pkgs.kubectl
    helm
    pkgs.k9s
    argocd
    pkgs.kustomize
    pkgs.kubecolor
    kubeseal
    kube-capacity
    pkgs.velero
    cilium-cli
    pkgs-unstable.egctl
    pkgs.talosctl
    longhorn-cli

    # Infrastructure as code
    pkgs-unstable.opentofu

    # Configuration management
    pkgs.ansible

    # Cloud
    awscli2
    pkgs.doctl
    stripe-cli

    # CI/CD
    pkgs.gh
    pkgs.act

    # DNS
    pkgs.drill
    pkgs.cli53

    # Secrets & encryption
    pkgs.sops
    pkgs.age
    bitwarden-cli # bw: Bitwarden password manager
    bws           # Bitwarden Secrets Manager
  ];

  # zsh completions not provided by the packages themselves (pkgs/ generate theirs at build time)
  programs.zsh.initContent = ''
    # `k` alias: kubecolor's completion file only registers kubectl
    compdef kubecolor=kubectl

    # tofu (`tf` alias) and aws only provide bash-style completion
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C ${lib.getExe pkgs-unstable.opentofu} tofu
    complete -C ${awscli2}/bin/aws_completer aws
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
