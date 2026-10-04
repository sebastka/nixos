{ pkgs, ... }:

{
  # Load the Yubikeys' PIV SSH keys into the agent, once per session (asks for the PIV PIN)
  home.shellAliases.ssh-add-yubikey = "ssh-add -s ${pkgs.yubico-piv-tool}/lib/libykcs11.so";

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
