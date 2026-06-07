{
  pkgs,
  pkgs-unstable,
  config,
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
    pkgs.talhelper
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
  ];

  xdg.configFile."kube/kuberc".text = ''
    # https://kubernetes.io/docs/reference/kubectl/kuberc/#suggested-defaults
    ---
    apiVersion: kubectl.config.k8s.io/v1beta1
    kind: Preference
    defaults:
      - command: apply  # (1) default server-side apply
        options:
          - name: server-side
            default: 'true'

      - command: delete  # (2) default interactive deletion
        options:
          - name: interactive
            default: 'true'

    credentialPluginPolicy: DenyAll  # See the above note about managed providers before selecting DenyAll
  '';
}
