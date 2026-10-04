{ fetchurl, stdenv, lib, unzip, autoPatchelfHook }:

let
  version = "2026.9.1";
  assets = {
    x86_64-linux  = { arch = "linux";       hash = "sha256-hCier1nWkfBCQmBREvIbAOjbplrN7bxg3eABooYPIJc="; };
    aarch64-linux = { arch = "linux-arm64"; hash = "sha256-xFHHczeKbx8EHqJlaKiXsoWoZWvuFqFuSRTOnkD7fHk="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "bitwarden-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "bitwarden-cli";
  inherit version;
  src = fetchurl {
    url = "https://github.com/bitwarden/clients/releases/download/cli-v${version}/bw-${asset.arch}-${version}.zip";
    inherit (asset) hash;
  };
  # Dynamically linked: point it to the C/C++ runtime in the Nix store
  nativeBuildInputs = [ unzip autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  # Node.js single executable: the application is embedded in the binary, stripping would break it
  dontStrip = true;
  sourceRoot = ".";
  installPhase = ''install -m755 -D bw $out/bin/bw'';
  meta = {
    description = "Bitwarden password manager CLI";
    homepage = "https://bitwarden.com/help/cli";
    mainProgram = "bw";
    platforms = builtins.attrNames assets;
  };
}
