{
  fetchurl,
  stdenv,
  lib,
}:

let
  version = "0.41.1";
  assets = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-+YFJH3/mDv8mNZa+K3PnwDNnNi0jZwH4410JyCersnQ=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-fcpz2/kmp4hSAWdrd8wmbROncJhGLKK9MqgMqtRkJkk=";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "kubeseal: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kubeseal";
  inherit version;
  src = fetchurl {
    url = "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${version}/kubeseal-${version}-linux-${asset.arch}.tar.gz";
    inherit (asset) hash;
  };
  sourceRoot = ".";
  installPhase = "install -m755 -D kubeseal $out/bin/kubeseal";
  meta = {
    description = "CLI for Sealed Secrets — encrypt Kubernetes secrets for safe GitOps storage";
    homepage = "https://github.com/bitnami-labs/sealed-secrets";
    platforms = builtins.attrNames assets;
  };
}
