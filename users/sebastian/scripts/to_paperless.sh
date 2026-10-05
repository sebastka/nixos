#!/usr/bin/env bash
# Upload documents to Paperless' consume directory, then move them to ./.moved
# Usage: to_paperless <file>...
# Packaged with writeShellApplication (users/sebastian/desktop.nix): it adds its own shebang and strict mode.

# Paperless runs on the talmox cluster, whatever KUBECONFIG is set to
export KUBECONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/kube/talmox/config.yaml"

namespace=paperless
app=paperless
container=consumer
destination=/usr/src/paperless/consume

[ "$#" -gt 0 ] || { echo "Usage: to_paperless <file>..." >&2; exit 2; }

pod="$(kubectl get pods -n "$namespace" -l app.kubernetes.io/name="$app" -o jsonpath='{.items[0].metadata.name}')"
mkdir -p .moved

for file in "$@"; do
    kubectl -n "$namespace" cp "$file" "${pod}:${destination}/" -c "$container"
    mv "$file" .moved/
done
