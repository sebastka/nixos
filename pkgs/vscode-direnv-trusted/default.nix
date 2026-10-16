{ vscode-utils }:

# direnv-trusted (ours: github.com/sebastka/vscode-extensions), from the Marketplace: a project's .envrc loaded by
# direnv only in trusted workspaces. Universal: one build for every platform.
vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    publisher = "SebastianKarlsen";
    name = "direnv-trusted";
    version = "0.1.0";
    hash = "sha256-AInI+YutEEzyKxMYSAElts3Qshl/FSZaFUvxcAOzzuE=";
  };
  meta = {
    description = "direnv's environment in VS Code, in trusted workspaces only";
    homepage = "https://github.com/sebastka/vscode-extensions/tree/master/extensions/direnv-trusted";
  };
}
