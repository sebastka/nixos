#!/usr/bin/env bash
# Update the code's dependencies: flake.lock inputs and the packages in pkgs/.
# Run by the "Update dependencies" workflow, or locally to update without waiting for it.
# Prints a Markdown summary on stdout (used as pull request body).
#
# Usage: ./scripts/update.sh
set -euo pipefail
cd "$(dirname "$0")/.." # Repo root

nix="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

echo "## flake.lock"
echo '```'
${nix} flake update 2>&1 | grep -v '^warning:' || true
echo '```'

echo "## pkgs"
pkgs="$(./scripts/update-pkgs.sh)"
echo "${pkgs:-No updates}"
