#!/usr/bin/env bash
# Deploy a host's NixOS configuration, as it is in the code on origin/master. Never changes the code:
# - Update dependencies with scripts/update.sh (or the "Update dependencies" workflow)
# - Check everything with `nix flake check`
#
# Usage: scripts/build.sh [host]   (this host by default)
# Another host is built on itself (no Nix trust needed there: only the derivations are copied to it, from the
# substituters otherwise), then switched over SSH, with sudo's password asked once.
set -euxo pipefail
cd "$(dirname "$0")/.." # Repo root

host="${1:-$(hostname)}"
test -f "hosts/${host}/default.nix" || {
    hosts=(hosts/*/default.nix)
    hosts=("${hosts[@]#hosts/}")
    echo "Unknown host ${host}, one of: ${hosts[*]%/default.nix}" >&2
    exit 1
}

# Use what is on origin/master (fast-forward only: stops if local commits diverge)
if [ "$(git branch --show-current)" = master ]; then
    git pull --ff-only origin master
else
    echo "Not on master: skipping git pull" >&2
fi

# nixos-rebuild, its build shown by nom (nix-output-monitor, in the dev shell: what downloads and builds, and how
# long) when available. Usage: rebuild <sudo|...> <nixos-rebuild arguments>: sudo for this host, as root; otherwise
# as the user, whose SSH agent and known_hosts reach the other host.
rebuild() {
    local sudo=()
    if [ "$1" = sudo ]; then
        sudo -v # Asks for the password now, not under nom's display
        sudo=(sudo)
    fi
    shift
    if command -v nom >/dev/null; then
        "${sudo[@]}" nixos-rebuild "$@" --log-format internal-json -v |& nom --json
    else
        "${sudo[@]}" nixos-rebuild "$@"
    fi
}

# --no-update-lock-file: fail instead of writing flake.lock (e.g. new input in flake.nix)
if [ "${host}" = "$(hostname)" ]; then
    rebuild sudo switch --flake ".#${host}" --no-update-lock-file
else
    target="sebastian@${host}.home.karlsen.fr"
    # Reachable, before evaluating anything: not when off (zeus: ssh helios.home.karlsen.fr wake zeus), or away from
    # the LAN and tailnet
    ssh -o ConnectTimeout=5 -o BatchMode=yes "${target}" true || {
        echo "${host} is not reachable over SSH (${target})" >&2
        exit 1
    }
    rebuild user switch --flake ".#${host}" --no-update-lock-file \
        --build-host "${target}" --target-host "${target}" \
        --ask-sudo-password
fi
