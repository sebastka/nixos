{ fetchurl, stdenv, lib }:

let
  version = "0.8.0";
  assets = {
    x86_64-linux  = { arch = "x86_64"; hash = "sha256-YQzm5df1KN8cYNO14nfQCsQ839nOTTbwsxMrto/BLPM="; };
    aarch64-linux = { arch = "arm64";  hash = "sha256-70ugxDtX1u/ARyzkZfaaYQK97rFlQRIOoaUQotL5hGU="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "kube-capacity: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kube-capacity";
  inherit version;
  src = fetchurl {
    url = "https://github.com/robscott/kube-capacity/releases/download/v${version}/kube-capacity_v${version}_linux_${asset.arch}.tar.gz";
    inherit (asset) hash;
  };
  sourceRoot = ".";
  installPhase = ''install -m755 -D kube-capacity $out/bin/kube-capacity'';
  meta = {
    description = "Simple CLI for showing resource requests, limits, and utilization in a Kubernetes cluster";
    homepage = "https://github.com/robscott/kube-capacity";
    platforms = builtins.attrNames assets;
  };
}
