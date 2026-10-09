{
  fetchurl,
  stdenv,
  lib,
  unzip,
}:

let
  version = "2.37.11";
  assets = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-QeHPXjAe0E7OLKPC2L32w1hOi2cpImlonMPoD5feceo=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-dZ9MdcgywXHOFAGpVsW2yf6TLDEeNnhjRGQb12ra8Io=";
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
