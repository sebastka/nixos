{ fetchurl, stdenv, lib }:

let
  version = "1.42.1";
  assets = {
    x86_64-linux  = { arch = "x86_64"; hash = "sha256-X/YyCWIH/JA+7Pmxyv400fkNSd89VeB8wyoHL2O1LAQ="; };
    aarch64-linux = { arch = "arm64";  hash = "sha256-bTpB/VnLX61oeuRXJnYFedWKNYQjvZbMVOtSbDRTOTE="; };
  };
  asset = assets.${stdenv.hostPlatform.system}
    or (throw "stripe-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "stripe-cli";
  inherit version;
  src = fetchurl {
    url = "https://github.com/stripe/stripe-cli/releases/download/v${version}/stripe_${version}_linux_${asset.arch}.tar.gz";
    inherit (asset) hash;
  };
  sourceRoot = ".";
  installPhase = ''install -m755 -D stripe $out/bin/stripe'';
  meta = {
    description = "Stripe CLI tool for interacting with the Stripe API";
    homepage = "https://stripe.com/docs/stripe-cli";
    platforms = builtins.attrNames assets;
  };
}
