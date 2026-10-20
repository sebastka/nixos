{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
}:

# Linux Mint's wallpaper packs, one per release (mint-backgrounds-<codename>: Maya, 13, to Wilma, 22; Mint 22.1 and
# later add theirs to mint-artwork, installed by Cinnamon's module), plus Retro and Wallpapers. Their images
# (share/backgrounds/linuxmint-<name>) and their lists for Cinnamon and GNOME (share/*-background-properties); not
# their Plasma and MATE copies. About 1.1 GB: only with Cinnamon (./default.nix), not in pkgs/ (built by every CI run).
# Frozen releases: no updates to follow (bin/update-pkgs). Versions and hashes: packages.linuxmint.com, e.g.
#   curl -s http://packages.linuxmint.com/dists/zena/main/binary-amd64/Packages.gz | gunzip | grep -A1 '^Package: mint-backgrounds'
let
  packs = {
    maya = {
      version = "1.5";
      hash = "sha256-xHP1DyPjR4ZJkq1+q2o9ZnzEoaeNf2w6i7YyTrS6vcI=";
    };
    nadia = {
      version = "1.4";
      hash = "sha256-T4TeuB8Dvz/X41k8iIj3noz14vYeMM03SjX3M0B4vSg=";
    };
    olivia = {
      version = "1.7";
      hash = "sha256-7MP5ALNL1aUnu1kKL+84rZP84qs8RJ1LdblUExWJAT0=";
    };
    petra = {
      version = "1.7";
      hash = "sha256-gDbKSr3iZAV+WjYvoOBiaNTYHjA6by1BNiL69+hjLS0=";
    };
    qiana = {
      version = "1.5";
      hash = "sha256-AZ125OXb5HXXJcauQZkl7/wPgKBpxPuqPzjwTYLH7cU=";
    };
    rafaela = {
      version = "1.2";
      hash = "sha256-sbFauQSXLtPUUWmH7WqiJTaWX0GGlvDmviFLdV+C05g=";
    };
    rebecca = {
      version = "1.5";
      hash = "sha256-UW+JZdYlJNTUsvRZYdvbylklzZbBV7fmd48BmLqlLsM=";
    };
    retro = {
      version = "1.3";
      hash = "sha256-CR8llQqK1ujKn8m2UuAylbV5HP8+PzwkQ2wuOnmNpT8=";
    };
    rosa = {
      version = "1.2";
      hash = "sha256-ucQyHHdNvLj65Z+nVSkjg/b8PxqiWnz7ZGMwkzCSv0k=";
    };
    sarah = {
      version = "1.1";
      hash = "sha256-X505kaoc4issRyhtU2721n1d9XfMPwkt1Nh/alF2CXw=";
    };
    serena = {
      version = "1.1";
      hash = "sha256-s9fFjjJ3D7sltAoBXR4LgfdiuxREzGkTxiZYzmitQ7M=";
    };
    sonya = {
      version = "1.1";
      hash = "sha256-R3kCTdhWpDs+Ot8jUccjhzpFFrWfWAb1aPzEwUPXNkg=";
    };
    sylvia = {
      version = "1.2";
      hash = "sha256-GAlE1H7JVDaoKln4cEzk2sxu8ILxWKr+Avi5ptQGd8I=";
    };
    tara = {
      version = "1.1";
      hash = "sha256-fmU9earSzVSGScK0sfSihI63l1EO4HHTktEc+U8A/JU=";
    };
    tessa = {
      version = "1.1";
      hash = "sha256-KFDG4KCmxdKUZxlULe0Xn9SU2fxMF09LdE1p/5wrMBw=";
    };
    tina = {
      version = "1.2";
      hash = "sha256-455cXM6cB3PSMmK4iqUDk571aEgblUvgk5T9iEuvyAA=";
    };
    tricia = {
      version = "1.1";
      hash = "sha256-UxNWwWW0GmDsYxKKfpaF/yMQinI8gHM+Qt4arUP8P2c=";
    };
    ulyana = {
      version = "1.1";
      hash = "sha256-qK0wUbAg+cnG1O2VWZmgAJ40tVOKiLdNej5vV9z7jq8=";
    };
    ulyssa = {
      version = "1.1";
      hash = "sha256-GwjbrGjmyabKwC6C7RuCtkgnPgn5P0TNY+uOZ7gPIcI=";
    };
    uma = {
      version = "1.2";
      hash = "sha256-LqIrwqUZkPWCEbPkmMJk2GFjlNJwK95jYbq47kbicks=";
    };
    una = {
      version = "1.1";
      hash = "sha256-+DpqN1DFz2/CAQbRZfNKnSmnXhybKdkKF308aTL06fw=";
    };
    vanessa = {
      version = "1.1";
      hash = "sha256-orxe+AKuHEYEzT7zblRBFl7o6jMcHlCAWvFw0nPmZsU=";
    };
    vera = {
      version = "1.0";
      hash = "sha256-1j170bOpNZetwBKLRQPh90f2LPgqqa2Ja3ba6O3EsLo=";
    };
    victoria = {
      version = "1.2";
      hash = "sha256-bMfgn6OVwvn1l2kIEgnlna9j9TiwHeecno57yAOevvc=";
    };
    virginia = {
      version = "1.1";
      hash = "sha256-rZXj9VTSh8g3sh9VyAB/sGgL5FFx7iTW4A3G7bacvjo=";
    };
    wallpapers = {
      version = "1.0";
      hash = "sha256-CUOU1YZl7iZxP+aJl2nTxvXf8wJCF/R3y+Ev+IDiPyI=";
    };
    wilma = {
      version = "1.1";
      hash = "sha256-U1LC5xdbECIJjfp36F7DzVaBBElOkDqXw0ERhXT1Dmc=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "mint-backgrounds";
  version = packs.wilma.version;

  srcs = lib.mapAttrsToList (
    name: pack:
    fetchurl {
      url = "http://packages.linuxmint.com/pool/main/m/mint-backgrounds-${name}/mint-backgrounds-${name}_${pack.version}_all.deb";
      inherit (pack) hash;
    }
  ) packs;

  nativeBuildInputs = [ dpkg ];

  unpackPhase = ''
    for src in $srcs; do
      dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-owner --no-same-permissions \
        ./usr/share/backgrounds ./usr/share/cinnamon-background-properties ./usr/share/gnome-background-properties \
        2> /dev/null || true # Not every pack has each directory
    done
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/share $out/
    # The lists name each image by its path on Mint
    find $out/share/*-background-properties -name '*.xml' -exec sed -i "s|/usr/share/|$out/share/|g" {} +
  '';

  # Every image the lists name is there
  doInstallCheck = true;
  installCheckPhase = ''
    grep -ho "$out/share/[^<]*" $out/share/*-background-properties/*.xml | sort -u | while read -r file; do
      [ -e "$file" ] || { echo "missing: $file" >&2; exit 1; }
    done
  '';

  meta = {
    description = "Linux Mint's wallpapers, for Cinnamon and GNOME";
    homepage = "http://packages.linuxmint.com/pool/main/m/";
    # The packages: GPL-3.0 (debian/copyright). The images: their artists' licenses (Credits, in each pack's
    # directory), mostly the Unsplash License.
    license = lib.licenses.unfreeRedistributable;
    platforms = lib.platforms.all;
  };
}
