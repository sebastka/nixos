{ fetchurl, stdenv, lib }:

let
  version = "1.53.0";
  assets = {
    x86_64-linux  = { arch = "x86_64"; hash = "sha256-oSIF30rssYFTuLP3bVApOGselJRNVZkA+QgspImoUhs="; };
    aarch64-linux = { arch = "arm64";  hash = "sha256-bMGV2mCBI3Y09bf+uk4unXHTPtgF1iGeRD/QZvrgcQk="; };
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
