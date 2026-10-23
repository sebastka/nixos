{
  fetchurl,
  stdenv,
  lib,
  unzip,
}:

let
  version = "2.38.5";
  assets = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-Xe99G35V2JL5o4G7LLIIGmhXEkZL4NNtXXBq8KxI0NM=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-B3Eak26dJxBFq5N9LCxTkMJfQZ5LqeJa256ZYDHj9r4=";
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
