#!/bin/sh
# Install a host from the NixOS live ISO:
# 1. Set up GnuPG + pcscd so the Yubikey can decrypt sops secrets, and decrypt the host's install secrets
# 2. Wipe, partition, format and mount the disk from hosts/<host>/disko.nix, enroll the Yubikey for LUKS
# 3. Restore the pre-generated SSH host key (so sops-nix can decrypt secrets on first boot)
#    and Secure Boot keys (if the host has some)
# 4. Install NixOS
#
# Usage: ./install.sh <host>   (as the live ISO user, from the repo root, Yubikey plugged in)
set -eu

host="${1:?Usage: $0 <host>}"
root="/mnt"
ssh_secrets="secrets/${host}-ssh-host-key.sops.yaml"
sb_secrets="secrets/${host}-secure-boot.sops.yaml"
gpg_key="0B25B26C537B40B5B208F3A6C74C02E66D0CBECF"  # sebastian@karlsen.fr
nix="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

test -f "hosts/${host}/disko.nix" || { echo "Missing hosts/${host}/disko.nix" >&2; exit 1; }
test -f "${ssh_secrets}" || { echo "Missing ${ssh_secrets}" >&2; exit 1; }

# 1. GnuPG and pcscd (with the CCID driver for the Yubikey)
# Packages come from this flake's locked nixpkgs (--inputs-from .); ^out/^bin avoids extra outputs (man, lib...).
gnupg="$(${nix} build --no-link --print-out-paths --inputs-from . 'nixpkgs#gnupg^out')"
jq="$(${nix} build --no-link --print-out-paths --inputs-from . 'nixpkgs#jq^bin')"
sops="$(${nix} build --no-link --print-out-paths --inputs-from . 'nixpkgs#sops^out')"
pcscd="$(${nix} build --no-link --print-out-paths --inputs-from . 'nixpkgs#pcsclite^out')/bin/pcscd"
ccid="$(${nix} build --no-link --print-out-paths --inputs-from . 'nixpkgs#ccid^out')"
export PATH="${gnupg}/bin:${jq}/bin:${sops}/bin:${PATH}"

if ! pgrep -x pcscd > /dev/null; then
    # Polkit on the live ISO does not know pcscd's actions, so it would deny the non-root user.
    sudo env PCSCLITE_HP_DROPDIR="${ccid}/pcsc/drivers" "${pcscd}" --disable-polkit
fi

install -d -m 700 "${HOME}/.gnupg"
grep -qx disable-ccid "${HOME}/.gnupg/scdaemon.conf" 2> /dev/null \
    || echo disable-ccid >> "${HOME}/.gnupg/scdaemon.conf"  # Use pcscd, not scdaemon's own USB driver
gpgconf --kill scdaemon
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "${gpg_key}"
gpg --card-status > /dev/null  # Links the public key to the Yubikey's private keys

# Decrypt now (once per file), so a Yubikey/sops failure aborts before the disk is wiped.
# The live ISO runs from RAM, so the temporary directory never touches a disk.
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
sops decrypt --output-type json "${ssh_secrets}" > "${tmp}/ssh.json"
if test -f "${sb_secrets}"; then
    sops decrypt --output-type json "${sb_secrets}" > "${tmp}/sb.json"
fi

# Write a key of a decrypted secrets file to a root-owned file, byte for byte.
# Usage: write_secret <json> <key> <destination>
write_secret() {
    jq -j --arg key "$2" '.[$key]' "$1" | sudo sh -c "umask 077 && cat > '$3'"
}

# 2. Partitioning
lsblk
printf 'This will ERASE the disk defined in hosts/%s/disko.nix. Type "yes" to continue: ' "${host}"
read -r answer
test "${answer}" = yes || exit 1
# shellcheck disable=SC2086 # ${nix} is intentionally split into command + flags
sudo ${nix} run --inputs-from . disko -- --mode destroy,format,mount --yes-wipe-all-disks --flake ".#${host}"

# Enroll the Yubikey (FIDO2) as LUKS unlock method: asks for the passphrase, FIDO2 PIN and a touch.
# The passphrase stays enrolled as recovery.
sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/disk-main-luks

# 3. SSH host key and Secure Boot keys
sudo install -d -m 755 "${root}/etc/ssh"
write_secret "${tmp}/ssh.json" ssh_host_ed25519_key "${root}/etc/ssh/ssh_host_ed25519_key"
sudo ssh-keygen -y -f "${root}/etc/ssh/ssh_host_ed25519_key" | sudo tee "${root}/etc/ssh/ssh_host_ed25519_key.pub" > /dev/null

if test -f "${tmp}/sb.json"; then
    # Same layout as `sbctl create-keys`, at boot.lanzaboote.pkiBundle
    sudo install -d -m 700 "${root}/var/lib/sbctl"
    write_secret "${tmp}/sb.json" GUID "${root}/var/lib/sbctl/GUID"
    for k in PK KEK db; do
        sudo install -d -m 700 "${root}/var/lib/sbctl/keys/${k}"
        write_secret "${tmp}/sb.json" "${k}.key" "${root}/var/lib/sbctl/keys/${k}/${k}.key"
        write_secret "${tmp}/sb.json" "${k}.pem" "${root}/var/lib/sbctl/keys/${k}/${k}.pem"
    done
fi

# 4. Install (passwords come from sops, no root password prompt)
sudo nixos-install --flake ".#${host}" --no-root-passwd
