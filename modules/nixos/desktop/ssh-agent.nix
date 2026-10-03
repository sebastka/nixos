{ ... }:

{
  # OpenSSH agent (systemd user service), used with the Yubikey-backed ed25519-sk key.
  # Plasma's ksshaskpass handles passphrase and touch prompts.
  programs.ssh.startAgent = true;
}
