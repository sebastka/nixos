#!/usr/bin/env bash
# kubectl exec credential plugin for topf's break-glass admin: mints a fresh 12h system:masters client certificate
# with `topf kubeconfig` (offline, from the cluster's secrets bundle) and prints it as an ExecCredential. No admin key
# is stored in the kubeconfig between uses, and the credential never goes stale.
# Usage: topf-kube-credential <path to topf.yaml>
# Generic: topf resolves secretsPath and schematics relative to the topf.yaml. The kubeconfig calls this by its bare
# name, as the kuberc allowlist names it (modules/home/programs/ops); homelab's talos/kubeconfig.sh writes such a user.
# No expirationTimestamp: kubectl does not cache exec credentials across invocations, and client-go reruns it on a 401.
# Packaged with writeShellApplication (users/sebastian/home.nix): it adds its own shebang and strict mode.

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  printf -- 'usage: topf-kube-credential <path to topf.yaml>\n' >&2
  exit 1
fi

# Captured first: a topf (or sops) failure must stop here, not feed an empty document to yq
kubeconfig="$(TOPFCONFIG="$1" topf kubeconfig)"

printf -- '%s\n' "$kubeconfig" | yq -o json '.users[0].user' | jq '{
  apiVersion: "client.authentication.k8s.io/v1",
  kind: "ExecCredential",
  status: {
    clientCertificateData: (."client-certificate-data" | @base64d),
    clientKeyData: (."client-key-data" | @base64d)
  }
}'
