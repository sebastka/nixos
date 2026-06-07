{ fetchurl, stdenv, lib }:

let
  version = "3.4.3";
  assets = {
    x86_64-linux  = { arch = "amd64"; hash = "sha256-+yMPl7qHs5N0aszxZwZ+C3XSDS3l7nz4R9UNQ2H5Ll8="; };
    aarch64-linux = { arch = "arm64"; hash = "sha256-hwWqJImls7mvDbh6lg9J424uPz3ESJc28dKPMbT341Y="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "argocd: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "argocd";
  inherit version;
  src = fetchurl {
    url = "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-${asset.arch}";
    inherit (asset) hash;
  };
  dontUnpack = true;
  installPhase = ''install -m755 -D $src $out/bin/argocd'';
  meta = {
    description = "Declarative GitOps CD for Kubernetes";
    homepage = "https://argo-cd.readthedocs.io";
    platforms = builtins.attrNames assets;
  };
}
