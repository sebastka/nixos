{ config, self, ... }:

# Our Nix binary cache: Attic (https://github.com/zhaofengli/attic) at https://attic.karlsen.app/ (sebastka/homelab:
# k8s/applications/utils/attic), cache `pithos`, after cache.nixos.org (priority 41 vs 40): what it doesn't have, built
# by CI. Unreachable (offline, cluster down): Nix tries for 5 s, then builds locally (fallback).

# Setup the Attic server (once), with the Attic client (modules/home/programs/ops) and a short-lived admin token:
#
#   kubectl -n attic exec deploy/attic -- atticadm -f /etc/attic/server.toml make-token --sub admin --validity '1 day' --pull '*' --push '*' --delete '*' --create-cache '*' --configure-cache '*' --configure-cache-retention '*' --destroy-cache '*'
#   attic login karlsen https://attic.karlsen.app <token>
#   attic cache create karlsen:pithos   # Private by default
#   attic cache info karlsen:pithos     # Public Key: extra-trusted-public-keys below
#
# Tokens, each stored where it's used:
#
#   # CI (push): its repository secret ATTIC_TOKEN
#   kubectl -n attic exec deploy/attic -- atticadm -f /etc/attic/server.toml make-token --sub ci --validity '1 year' --pull pithos --push pithos

#   # Each host (pull only): attic-pull-token in secrets/<host>.sops.yaml (sops edit)
#   for h in geras zeus hermes helios boreas; do
#     echo "$h:"; kubectl -n attic exec deploy/attic -- atticadm -f /etc/attic/server.toml make-token --sub "$h" --validity '1 year' --pull pithos
#   done
#
# Push by hand: attic push karlsen:pithos <store paths>
{
  sops.secrets.attic-pull-token.sopsFile = "${self}/secrets/${config.networking.hostName}.sops.yaml";
  sops.templates."nix-netrc".content = ''
    machine attic.karlsen.app
    password ${config.sops.placeholder.attic-pull-token}
  '';

  nix.settings = {
    extra-substituters = [ "https://attic.karlsen.app/pithos" ];
    extra-trusted-public-keys = [ "pithos:pir3vRe6RpQrNmkwB6M0F/ydWPDgQqe5v6mABkmCpYc=" ];
    netrc-file = config.sops.templates."nix-netrc".path;
    connect-timeout = 5;
    fallback = true;
  };
}
