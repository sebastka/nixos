{ fetchurl, stdenv, lib, unzip }:

let
  version = "2.1.0";
  # Statically linked (musl) builds: no patching needed on NixOS
  assets = {
    x86_64-linux  = { arch = "x86_64";  hash = "sha256-9Z7hUOQrghKNQ3CH6brJIAU8a/3cuWDSDOk4blrJu6Y="; };
    aarch64-linux = { arch = "aarch64"; hash = "sha256-6w8a5h0cO3QkTShBIzJ24Fx36L5NoZftkPxiSDhwBeE="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "bws: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "bws";
  inherit version;
  src = fetchurl {
    url = "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${version}/bws-${asset.arch}-unknown-linux-musl-${version}.zip";
    inherit (asset) hash;
  };
  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";
  installPhase = ''install -m755 -D bws $out/bin/bws'';
  meta = {
    description = "Bitwarden Secrets Manager CLI";
    homepage = "https://bitwarden.com/help/secrets-manager-cli";
    mainProgram = "bws";
    platforms = builtins.attrNames assets;
  };
}
