#!/usr/bin/env bash
# Update the version and per-architecture hashes of the packages in pkgs/ to their latest upstream release.
# Prints a Markdown list of the updates on stdout (used as pull request body).
#
# Usage: ./scripts/update-pkgs.sh
set -euo pipefail
cd "$(dirname "$0")/.." # Repo root

nix="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

# Package directory, upstream Git repository, tag prefix
packages=(
    "ansible-lint   ansible/ansible-lint        v"
    "argocd         argoproj/argo-cd            v"
    "awscli2        aws/aws-cli                 -"
    "bitwarden-cli  bitwarden/clients           cli-v"
    "bws            bitwarden/sdk-sm            bws-v"
    "cilium-cli     cilium/cilium-cli           v"
    "domeneshop-cli sebastka/domeneshop-sdk     v"
    "helm           helm/helm                   v"
    "kube-capacity  robscott/kube-capacity      v"
    "kubeseal       bitnami-labs/sealed-secrets v"
    "longhorn-cli   longhorn/cli                v"
    "mailcore-cli   Fjordmail/mailcore-cli      v"
    "stripe-cli     stripe/stripe-cli           v"
    "topf           postfinance/topf            v"
    "vscode-opentofu opentofu/vscode-opentofu   v"
    "yamllint       adrienverge/yamllint        v"
    "zitadel        zitadel/zitadel             v"
)

# Latest stable (X.Y.Z, no pre-release) tag of a GitHub repository, without its prefix.
latest_version() {
    local repo="$1" prefix="$2"
    [ "${prefix}" = "-" ] && prefix=""
    git ls-remote --tags --refs "https://github.com/${repo}" \
        | sed -n "s|.*refs/tags/${prefix}\([0-9]\+\.[0-9]\+\.[0-9]\+\)$|\1|p" \
        | sort -V | tail -n 1
}

# Download URL of a package for a system (flake output packages.<system>.<package>).
src_url() {
    local pkg="$1" system="$2"
    ${nix} eval --raw ".#packages.${system}.${pkg}.src.url"
}

# Hash the build of a package reports for its first fixed-output derivation with an empty hash.
build_hash_mismatch() {
    local pkg="$1" log hash
    log="$(${nix} build --no-link ".#${pkg}" 2>&1 || true)"
    hash="$(sed -n 's|.*got: *\(sha256-[A-Za-z0-9+/=]*\).*|\1|p' <<< "${log}" | head -n 1)"
    if [ -z "${hash}" ]; then
        echo "${pkg}: no hash mismatch reported by the build" >&2
        echo "${log}" >&2
        exit 1
    fi
    echo "${hash}"
}

for entry in "${packages[@]}"; do
    read -r pkg repo prefix <<< "${entry}"
    file="pkgs/${pkg}/default.nix"

    current="$(sed -n 's|^ *version = "\(.*\)";|\1|p' "${file}")"
    latest="$(latest_version "${repo}" "${prefix}")"
    if [ -z "${latest}" ]; then
        echo "${pkg}: no release found in ${repo}" >&2
        exit 1
    fi
    # Skip if up to date (or if the latest tag is somehow older than the current version)
    if [ "$(printf '%s\n%s\n' "${current}" "${latest}" | sort -V | tail -n 1)" = "${current}" ]; then
        echo "${pkg}: ${current} is up to date" >&2
        continue
    fi

    echo "${pkg}: ${current} -> ${latest}" >&2
    sed -i -E "s|^( *version = \")[^\"]*(\";)|\1${latest}\2|" "${file}"

    # Release binaries: one entry per system (`<system> = {`, then its own `hash = "...";` line, then `};`, as nixfmt
    # lays them out), each hash prefetched from its URL
    systems="$(sed -n 's|^ *\([a-z0-9_]*-linux\) *= *{ *$|\1|p' "${file}")"
    for system in ${systems}; do
        url="$(src_url "${pkg}" "${system}")"
        hash="$(${nix} store prefetch-file --json --hash-type sha256 "${url}" | sed -n 's|.*"hash":"\([^"]*\)".*|\1|p')"
        sed -i -E "/^ *${system} *= *\{ *$/,/^ *\};/ s|^( *hash = \")[^\"]*(\";)|\1${hash}\2|" "${file}"
    done

    # Built from source (no per-system entries): emptied, each hash is reported by the build (source first, then
    # dependencies)
    if [ -z "${systems}" ]; then
        for attr in hash vendorHash; do
            grep -qE "^ *${attr} = \"" "${file}" || continue
            sed -i -E "s|^( *${attr} = \")[^\"]*(\";)|\1\2|" "${file}"
            hash="$(build_hash_mismatch "${pkg}")"
            sed -i -E "s|^( *${attr} = \")[^\"]*(\";)|\1${hash}\2|" "${file}"
        done
    fi

    echo "- \`${pkg}\`: ${current} → ${latest} ([releases](https://github.com/${repo}/releases))"
done
