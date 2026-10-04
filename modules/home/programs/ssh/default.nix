{ pkgs, ... }:

{
  # Load the Yubikeys' PIV SSH keys into the agent, once per session (asks for the PIV PIN)
  home.shellAliases.ssh-add-yubikey = "ssh-add -s ${pkgs.yubico-piv-tool}/lib/libykcs11.so";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Work servers: Yubikey-backed (FIDO2) inboxcom key
    settings."*.fjordmail.no" = {
      IdentityFile = "~/.ssh/key/inboxcom.id_ed25519_sk_rk";
    };

    # Always written last by home-manager, so the blocks above take precedence.
    settings."*" = {
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      AddKeysToAgent = "yes";
      # Only offer the configured keys, not every key in the agent: both keys are
      # registered on GitHub, which picks the account from the first key accepted.
      IdentitiesOnly = "yes";
      IdentityFile = "~/.ssh/key/private.id_ed25519_sk_rk"; # Yubikey-backed (FIDO2) resident key, restore with `ssh-keygen -K`
    };
  };
}
