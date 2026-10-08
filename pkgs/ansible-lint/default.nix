{ pkgs-unstable }:

# ansible-lint's latest release: nixpkgs' (even unstable's) lags behind. Unstable's package, with the newer source:
# same Python libraries and Ansible as the ansible from nixpkgs-unstable (modules/home/programs/ops).
let
  version = "26.9.0";
  yamllint = import ../yamllint { inherit pkgs-unstable; }; # Requires a newer one too
in
pkgs-unstable.ansible-lint.overridePythonAttrs (old: {
  inherit version;
  src = pkgs-unstable.fetchPypi {
    inherit version;
    pname = "ansible_lint";
    hash = "sha256-yzJliI8wgV3g3PCWTTR2i0XJi7Q2Hup+tCwDQugbUbQ=";
  };
  dependencies =
    map (dep: if dep.pname or "" == "yamllint" then yamllint else dep) old.dependencies
    ++ [ pkgs-unstable.python3Packages.distro ]; # New dependency
})
