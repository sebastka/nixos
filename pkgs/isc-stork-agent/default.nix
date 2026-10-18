{
  fetchurl,
  stdenv,
  lib,
  autoPatchelfHook,
  dpkg,
}:

# ISC Stork's agent (not in nixpkgs, whose "stork" is another project), from ISC's own Debian package: its version
# follows the Stork server's (ghcr.io/sebastka/stork, homelab repo: k8s/infrastructure/monitoring/stork).
let
  version = "2.4.2";
  build = "261002134402"; # ISC's package build, part of its file name
in
stdenv.mkDerivation {
  pname = "isc-stork-agent";
  inherit version;
  src = fetchurl {
    url = "https://dl.cloudsmith.io/public/isc/stork/deb/debian/pool/any-version/main/i/is/isc-stork-agent_${version}.${build}/isc-stork-agent_${version}.${build}_amd64.deb";
    hash = "sha256-XSGJpRBjnQMmTpD5bxMMw4ouZe58NfbboOXIYkgZenc=";
  };
  # Linked against glibc only (libc, libresolv, libpthread, libdl): its interpreter and RPATH for NixOS
  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];
  unpackPhase = "dpkg-deb -x $src .";
  installPhase = ''
    install -m755 -D usr/bin/stork-agent $out/bin/stork-agent
    install -m644 -D usr/share/man/man8/stork-agent.8 $out/share/man/man8/stork-agent.8
  '';
  meta = {
    description = "ISC Stork's agent: monitors Kea (and BIND 9) for the Stork server";
    homepage = "https://gitlab.isc.org/isc-projects/stork";
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "stork-agent";
  };
}
