{ php84, lib, fetchurl, installShellFiles, makeWrapper }:

# mailcore CLI, built with the lock of the (private) Fjordmail/mailcore-sdk monorepo: each release of the
# public Fjordmail/mailcore-cli has a mailcore-sdk-<version>.tar.gz with its composer.json, composer.lock and packages/.
# Update: scripts/update-pkgs.sh (version, then hash and vendorHash).
php84.buildComposerProject2 (finalAttrs: {
  pname = "mailcore-cli";
  version = "0.1.9";
  src = fetchurl {
    url = "https://github.com/Fjordmail/mailcore-cli/releases/download/v${finalAttrs.version}/mailcore-sdk-${finalAttrs.version}.tar.gz";
    hash = "sha256-KXZHChsPffIWqrrG+QX3Q26YYyRDL391v8EVaUpGUW4=";
  };
  vendorHash = "sha256-/l7scqMrfQ2kH0mcLmeTP1Qogn9vAF8mi+nqecI4XbU=";
  nativeBuildInputs = [ installShellFiles makeWrapper ];
  postInstall = ''
    # Run the CLI with nixpkgs' PHP (its shebang is `#!/usr/bin/env php`)
    makeWrapper ${lib.getExe php84} $out/bin/mailcore \
      --add-flags $out/share/php/${finalAttrs.pname}/vendor/bin/mailcore
    export HOME="$TMPDIR"
    installShellCompletion --cmd mailcore --zsh <($out/bin/mailcore completion zsh)
  '';
  meta = {
    description = "MailCore CLI (inboxcom/mailcore-cli)";
    homepage = "https://github.com/Fjordmail/mailcore-cli";
    license = lib.licenses.mit;
    mainProgram = "mailcore";
    platforms = lib.platforms.linux;
  };
})
