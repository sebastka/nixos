{ pkgs-unstable }:

# yamllint's latest release (nixpkgs' lags behind; pkgs/ansible-lint requires it): unstable's Python package, with the
# newer source. Its command for the user: modules/home/programs/ops.
let
  version = "1.38.0";
in
pkgs-unstable.python3Packages.yamllint.overridePythonAttrs {
  inherit version;
  src = pkgs-unstable.fetchPypi {
    inherit version;
    pname = "yamllint";
    hash = "sha256-CeXylTHaq5M2a7Bh52AZ1ekWke8KQDKPBMknOH0dNk0=";
  };
}
