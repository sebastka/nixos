{ pkgs-unstable }:

# Fractal's latest release (nixpkgs' lags behind): unstable's package (pkgs/by-name/fr/fractal), with the newer source
# and its Rust dependencies. Unstable's: its Rust dependencies need a newer Rust than stable's. Remove once nixpkgs
# catches up. Installed on the desktops: modules/nixos/desktop.
# Update: bin/update-pkgs (version, then hash and cargoHash).
let
  version = "14.3";
  cargoHash = "sha256-wRTXNnM8NscEjNbO7sXaO8LM1u2iuDYUtVuot7csBcg=";
in
pkgs-unstable.fractal.overrideAttrs (
  finalAttrs: _: {
    inherit version;
    src = pkgs-unstable.fetchFromGitLab {
      domain = "gitlab.gnome.org";
      owner = "World";
      repo = "fractal";
      tag = version;
      hash = "sha256-AHksQ+DXIf/wFj/K24xbiT5Qr6tbzRHOLnCDMlAbTC0=";
    };
    cargoDeps = pkgs-unstable.rustPlatform.fetchCargoVendor {
      inherit (finalAttrs) src;
      hash = cargoHash;
    };
  }
)
