{
  php84,
  lib,
  fetchFromGitHub,
  installShellFiles,
  makeWrapper,
}:

# domeneshop CLI with the dashboard:* commands (sebastka/domeneshop-dashboard, picked up when installed).
# Built from the monorepo the packages are split from: its root composer.lock pins every dependency.
# Update: scripts/update-pkgs.sh (version, then hash and vendorHash).
php84.buildComposerProject2 (finalAttrs: {
  pname = "domeneshop-cli";
  version = "0.3.0";
  src = fetchFromGitHub {
    owner = "sebastka";
    repo = "domeneshop-sdk";
    tag = "v${finalAttrs.version}";
    hash = "sha256-eNtTsH2DLk5NubKuin5BzSC38nuHZwEKXXfy+WJclKA=";
  };
  vendorHash = "sha256-lnF6L9nd6S2YkSLP6Zuiz5qIliMG/tMSfXhwQItynWw=";
  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];
  postInstall = ''
    # Run the CLI with nixpkgs' PHP (its shebang is `#!/usr/bin/env php`)
    makeWrapper ${lib.getExe php84} $out/bin/domeneshop \
      --add-flags $out/share/php/${finalAttrs.pname}/vendor/bin/domeneshop
    export HOME="$TMPDIR"
    installShellCompletion --cmd domeneshop --zsh <($out/bin/domeneshop completion zsh)
  '';
  meta = {
    description = "Domeneshop CLI, with the dashboard commands (sebastka/domeneshop-cli)";
    homepage = "https://github.com/sebastka/domeneshop-sdk";
    license = lib.licenses.mit;
    mainProgram = "domeneshop";
    platforms = lib.platforms.linux;
  };
})
