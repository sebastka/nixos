#!/bin/sh
# Deploy the hosts' NixOS configurations, as they are in the code on origin/master. Never changes the code:
# - Update dependencies with scripts/update.sh (or the "Update dependencies" workflow)
# - Check everything with `nix flake check`
set -eux
cd "$(dirname "$0")/.." # Repo root

# Use what is on origin/master (fast-forward only: stops if local commits diverge)
if [ "$(git branch --show-current)" = master ]; then
    git pull --ff-only origin master
else
    echo "Not on master: skipping git pull" >&2
fi

find hosts -mindepth 1 -maxdepth 1 -type d | cut -d'/' -f2 | while read host; do
    echo "${host}" | grep -qx geras && true || continue  # Temp: Only build geras for now

    # --no-update-lock-file: fail instead of writing flake.lock (e.g. new input in flake.nix)
    if hostname | grep -qx "${host}"; then
        sudo nixos-rebuild switch --flake ".#${host}" --no-update-lock-file
    else
        sudo nixos-rebuild switch --flake ".#${host}" --no-update-lock-file \
            --target-host "sebastian@${host}.home.karlsen.fr" \
            --use-remote-sudo
    fi
done
