#!/usr/bin/env bash
# Upload .torrent files to Deluge's watch directory for <dir>, then move them to ./.moved
# Usage: to_deluge <dir> <file>...
# Packaged with writeShellApplication (users/sebastian/desktop.nix): it adds its own shebang and strict mode.

# Deluge runs on the talmox cluster, whatever KUBECONFIG is set to
export KUBECONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/kube/talmox/config.yaml"

namespace=deluge
app=deluged
container=deluged
[ "$#" -ge 2 ] || { echo "Usage: to_deluge <dir> <file>..." >&2; exit 2; }
destination="/downloads/$1/.torrent"
shift

pod="$(kubectl get pods -n "$namespace" -l app.kubernetes.io/name="$app" -o jsonpath='{.items[0].metadata.name}')"
mkdir -p .moved

for file in "$@"; do
    kubectl -n "$namespace" cp "$file" "${pod}:${destination}/" -c "$container"
    mv "$file" .moved/
done
