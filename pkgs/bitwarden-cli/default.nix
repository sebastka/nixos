{ fetchurl, stdenv, lib, unzip }:

let
  version = "2026.9.1";
  assets = {
    x86_64-linux  = { arch = "linux";       hash = "sha256-hCier1nWkfBCQmBREvIbAOjbplrN7bxg3eABooYPIJc="; };
    aarch64-linux = { arch = "linux-arm64"; hash = "sha256-xFHHczeKbx8EHqJlaKiXsoWoZWvuFqFuSRTOnkD7fHk="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "bitwarden-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
# bw is a Node.js app packed with `pkg`: the application is appended to the binary, at an offset
# recorded inside it. Patching the ELF (autoPatchelf) moves the content of the x86_64 binary (not
# PIE), which breaks bw. So it is installed unmodified, and runs through nix-ld (programs.nix-ld,
# enabled on desktops, provides libstdc++ and libgcc_s). Consequence: it can't run in the build
# sandbox, so its zsh completion is generated on first use (see modules/home/programs/ops).
stdenv.mkDerivation {
  pname = "bitwarden-cli";
  inherit version;
  src = fetchurl {
    url = "https://github.com/bitwarden/clients/releases/download/cli-v${version}/bw-${asset.arch}-${version}.zip";
    inherit (asset) hash;
  };
  nativeBuildInputs = [ unzip ];
  # Leave the binary untouched: no stripping, no ELF patching
  dontStrip = true;
  dontPatchELF = true;
  sourceRoot = ".";
  installPhase = ''
    install -m755 -D bw $out/bin/bw
  '';
  meta = {
    description = "Bitwarden password manager CLI";
    homepage = "https://bitwarden.com/help/cli";
    mainProgram = "bw";
    platforms = builtins.attrNames assets;
  };
}
