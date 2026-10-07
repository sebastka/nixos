{
  stdenv,
  vscode-utils,
}:

# OpenTofu VS Code extension (not in nixpkgs), from the Marketplace: one build per platform, each bundling its language
# server (tofu-ls, a static binary)
let
  version = "0.6.3";
  assets = {
    x86_64-linux = {
      arch = "linux-x64";
      hash = "sha256-7Qy9W4hpt63MXx2PzsXOVzueRvTlfsxmw9U1djo6hf0=";
    };
    aarch64-linux = {
      arch = "linux-arm64";
      hash = "sha256-lHVe5s071OkMbAV2j5Uu0nIVLk60+DbTfZemEqaARdI=";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "vscode-opentofu: unsupported platform ${stdenv.hostPlatform.system}");
in
vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    publisher = "opentofu";
    name = "vscode-opentofu";
    inherit version;
    inherit (asset) arch hash;
  };
  meta = {
    description = "OpenTofu language support (syntax, completion, validation) for VS Code";
    homepage = "https://github.com/opentofu/vscode-opentofu";
    platforms = builtins.attrNames assets;
  };
}
