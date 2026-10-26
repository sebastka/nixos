{ ... }:

# sebastian on zeus only, imported by hosts/zeus/default.nix
{
  users.users.sebastian = {
    # User services from boot, not only while logged in: rootless Docker
    linger = true;
    # Also the work Yubikey's OpenPGP authentication subkey (../work.nix)
    openssh.authorizedKeys.keyFiles = [ ../keys/inboxcom.id_ed25519_gpg.pub ];
  };
}
