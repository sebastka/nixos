{
  fetchurl,
  stdenv,
  lib,
}:

let
  version = "0.41.2";
  assets = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-ZmtdtniK0d7bVuLZcGThzDd5qne71vS1a2K+6xlB7Xk=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-inPAslL2wOh1Knp0naUfVabpncVgPjvSntPAD/noLbI=";
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
