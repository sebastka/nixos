{ ... }:

{
  imports = [
    ./audio.nix
    ./fonts.nix
    ./gnupg.nix
    ./networkmanager.nix
    ./plasma.nix
    ./ssh-agent.nix
  ];

  services.printing.enable = true;

  programs.firefox.enable = true;

  programs.nix-ld.enable = true; # Allow dynamically-linked binaries from outside nixpkgs (e.g. VS Code extension bundled binaries)
  # programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];
}
