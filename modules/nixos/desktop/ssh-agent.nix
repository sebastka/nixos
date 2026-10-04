{ pkgs, ... }:

{
  # OpenSSH agent (systemd user service). Plasma's ksshaskpass handles passphrase and touch prompts.
  programs.ssh.startAgent = true;

  # SSH keys in the Yubikeys' PIV slot 9a, loaded once per session with `ssh-add-yubikey`
  # (PIN once, no touch). The agent only loads PKCS#11 libraries matching this pattern.
  programs.ssh.agentPKCS11Whitelist = "${pkgs.yubico-piv-tool}/lib/libykcs11*";

  environment.systemPackages = with pkgs; [
    yubico-piv-tool # libykcs11.so (PKCS#11 for PIV)
    yubikey-manager # ykman
  ];
}
