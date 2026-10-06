{ pkgs, self, ... }:

{
  # Tern mail client (https://github.com/sebastka/tern) on every desktop. Configuration is per user (~/.config/tern).
  environment.systemPackages = [
    self.inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.libsecret # secret-tool: store the account passwords (password.keyring) in the keyring
  ];
}
