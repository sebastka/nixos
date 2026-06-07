{ fetchurl, stdenv, lib }:

let
  version = "0.19.4";
  assets = {
    x86_64-linux  = { arch = "amd64"; hash = "sha256-mOzVVFkaWSsO4y9dc4cRM7zuBmOWGfHAMry6M5NA3CY="; };
    aarch64-linux = { arch = "arm64"; hash = "sha256-hmyGaDqmPJQ6lMoq9dwrDbNIPRw+2Mcrruq9EwYafkI="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "cilium-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "cilium-cli";
  inherit version;
  src = fetchurl {
    url = "https://github.com/cilium/cilium-cli/releases/download/v${version}/cilium-linux-${asset.arch}.tar.gz";
    inherit (asset) hash;
  };
  sourceRoot = ".";
  installPhase = ''install -m755 -D cilium $out/bin/cilium'';
  meta = {
    description = "CLI to install, manage and troubleshoot Kubernetes clusters running Cilium";
    homepage = "https://github.com/cilium/cilium-cli";
    platforms = builtins.attrNames assets;
  };
}
