{
  fetchurl,
  stdenv,
  lib,
  unzip,
}:

let
  version = "2.38.3";
  assets = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-rlX6SqZlP8KW846sUAhz47DnmNAqNfMFxpLQL8g1xUg=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-MEUtnS5Hl53cpd2dD8E8O0KtYYW0SRblTj9e8x/nDuk=";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "awscli2: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "awscli2";
  inherit version;
  src = fetchurl {
    url = "https://awscli.amazonaws.com/awscli-exe-linux-${asset.arch}-${version}.zip";
    inherit (asset) hash;
  };
  nativeBuildInputs = [ unzip ];
  dontUnpack = true;
  installPhase = ''
    unzip $src
    mkdir -p $out/bin $out/lib/aws-cli
    cp -r aws/dist $out/lib/aws-cli/
    ln -s $out/lib/aws-cli/dist/aws $out/bin/aws
    ln -s $out/lib/aws-cli/dist/aws_completer $out/bin/aws_completer
  '';
  meta = {
    description = "Unified tool to manage AWS services";
    homepage = "https://aws.amazon.com/cli";
    platforms = builtins.attrNames assets;
  };
}
