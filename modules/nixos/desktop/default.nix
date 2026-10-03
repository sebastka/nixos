{ ... }:

{
  imports = [
    ./audio.nix
    ./fonts.nix
    ./gnupg.nix
    ./networkmanager.nix
    ./plasma.nix
  ];

  services.printing.enable = true;

  programs.firefox.enable = true;

  programs.nix-ld.enable = true; # Allow dynamically-linked binaries from outside nixpkgs (e.g. VS Code extension bundled binaries)
  # programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10" # required by bitwarden-desktop; revisit when nixpkgs updates it
  ];
}
