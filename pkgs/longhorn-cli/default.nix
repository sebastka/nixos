{ fetchurl, stdenv, lib }:

let
  version = "1.13.0";
  assets = {
    x86_64-linux  = { arch = "amd64"; hash = "sha256-I1TsG5/wWPpLfheEUdNEWVnNS2QGMX13eLY38DFOEFE="; };
    aarch64-linux = { arch = "arm64"; hash = "sha256-RMICRMlFHrUiFnt6E2jn1NqHnnRosxolUhzDkEAigQM="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "longhorn-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "longhorn-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/longhorn/cli/releases/download/v${version}/longhornctl-linux-${asset.arch}";
    inherit (asset) hash;
  };

  dontUnpack = true;

  installPhase = ''
    install -m755 -D $src $out/bin/longhornctl
  '';

  meta = {
    description = "CLI for Longhorn distributed block storage";
    homepage = "https://longhorn.io";
    platforms = builtins.attrNames assets;
  };
}
