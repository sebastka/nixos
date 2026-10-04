{ fetchurl, stdenv, lib }:

let
  version = "4.3.0";
  assets = {
    x86_64-linux  = { arch = "amd64"; hash = "sha256-hlhKVN73NXBVj2b1ERzFPf7VZoljeuMsEgEgXUlPVPs="; };
    aarch64-linux = { arch = "arm64"; hash = "sha256-McV5TdVcZqUea30uKsehFK6LHeQf8dm6UXSKyXOwagg="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "helm: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "helm";
  inherit version;
  src = fetchurl {
    url = "https://get.helm.sh/helm-v${version}-linux-${asset.arch}.tar.gz";
    inherit (asset) hash;
  };
  installPhase = ''
    install -m755 -D helm $out/bin/helm
  '';
  meta = {
    description = "The Kubernetes package manager";
    homepage = "https://helm.sh";
    platforms = builtins.attrNames assets;
  };
}
