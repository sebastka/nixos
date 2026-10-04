{ fetchurl, stdenv, lib }:

let
  version = "0.20.1";
  assets = {
    x86_64-linux  = { arch = "amd64"; hash = "sha256-JOgX3PzIoS4yXOdUdhe8vPFxxbCzNbsk0rsSB7oEf2E="; };
    aarch64-linux = { arch = "arm64"; hash = "sha256-0jdVC4gq9vLgHomF4eAk1XwHdGEcClJ8eiDc7n3E/Qc="; };
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
