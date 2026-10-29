{
  fetchurl,
  stdenv,
  lib,
  unzip,
}:

let
  version = "2.39.1";
  assets = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-W2wQ4KjM3PMMhL1kP+pRHxA9JXpHh6fO+HhpHWMWmAQ=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-Wt8LUFKEPlQrVahG1JuiorPz+0lg81wR35rHw5XP+q8=";
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
