#!/bin/sh
set -eux

if find flake.lock -mtime +7 | grep -q .; then
    nix flake update
fi

find hosts -mindepth 1 -maxdepth 1 -type d | cut -d'/' -f2 | while read host; do
    echo "${host}" | grep -qx geras && true || continue  # Temp: Only build geras for now

    if hostname | grep -qx "${host}"; then
        sudo nixos-rebuild switch --flake ".#${host}"
    else
        sudo nixos-rebuild switch --flake ".#${host}" \
            --target-host "sebastian@${host}.home.karlsen.fr" \
            --use-remote-sudo
    fi
done
