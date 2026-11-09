{
  config,
  lib,
  pkgs,
  self,
  ...
}:

{
  # Tern mail client (https://github.com/sebastka/tern) on every desktop (built locally: ./uncached.nix). Configuration
  # is per user (~/.config/tern).
  environment.systemPackages =
    lib.optional config.desktop.uncachedPackages.enable
      self.inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default
    ++ [
      pkgs.libsecret # secret-tool: store the account passwords (password.keyring) in the keyring
    ];
}
