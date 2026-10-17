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

# The images have no tar (kubectl cp) nor shell, but Python: stream the file into it, written under a hidden
# name (._*, always ignored by Paperless' consumer; not *.torrent for Deluge's AutoAdd), then renamed in place
# so the app only ever sees complete files
upload() { # <file> <directory in the container>
    local name
    name="$(basename "$1")"
    kubectl -n "$namespace" exec -i "$pod" -c "$container" -- python3 -c '
import os, shutil, sys
directory, name = sys.argv[1], sys.argv[2]
part = os.path.join(directory, "._" + name + ".part")
try:
    with open(part, "wb") as f:
        shutil.copyfileobj(sys.stdin.buffer, f)
    os.replace(part, os.path.join(directory, name))
except BaseException:
    if os.path.exists(part):
        os.remove(part)
    raise
' "$2" "$name" <"$1"
}

pod="$(kubectl get pods -n "$namespace" -l app.kubernetes.io/name="$app" -o jsonpath='{.items[0].metadata.name}')"
mkdir -p .moved

for file in "$@"; do
    upload "$file" "$destination"
    mv "$file" .moved/
done
