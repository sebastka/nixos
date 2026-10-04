{ pkgs, ... }:

let
  libykcs11 = "${pkgs.yubico-piv-tool}/lib/libykcs11.so";
in
{
  # Load the Yubikeys' PIV SSH keys into the agent (asks for the PIV PIN): once per session,
  # and again after replugging a Yubikey (unloads the stale smartcard session first)
  home.shellAliases.ssh-add-yubikey = "ssh-add -e ${libykcs11} 2>/dev/null; ssh-add -s ${libykcs11}";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Identities (IdentityFile) are set per user, see users/*/home.nix.
    # Always written last by home-manager, so host-specific blocks take precedence.
    settings."*" = {
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      AddKeysToAgent = "yes";
      # Only offer the configured keys, not every key in the agent: both keys are
      # registered on GitHub, which picks the account from the first key accepted.
      IdentitiesOnly = "yes";
    };
  };
}
