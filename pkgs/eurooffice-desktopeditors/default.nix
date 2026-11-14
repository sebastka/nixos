# Euro-Office Desktop Editors (https://github.com/Euro-Office/DesktopEditors): the European fork of OnlyOffice's
# editors, not in nixpkgs. Its .deb release, x86_64 and arm64, run as is in a FHS environment: it bundles its own Qt 6
# and Chromium (CEF) in /opt/euro-office/euro-office, which its launcher (/usr/bin/euro-office-euro-office) expects
# there. Bound there read-only, unpatched; the environment provides the system libraries they link against.
#
# fonts: the font packages its documents can use (the system's: fonts.packages, modules/nixos/desktop). Its font list
# only takes real files in real directories (in /usr/share/fonts, ~/.local/share/fonts...), not the symlinks to the
# store fonts come as. Each one's share/fonts is mounted in an empty /usr/share/fonts instead, where they appear as
# real directories.
{
  fonts ? [ ],
  stdenv,
  lib,
  fetchurl,
  buildFHSEnv,
  dpkg,
}:
let
  version = "9.3.8";

  # Its .deb per architecture
  assets = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-GBbEzV1YBrdXRow9xX7HbCOs0eoIUtRB5Q1qVJ0hfaE=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-ax6zz6DzWzExK2TKxOVu6oxM/OXQNJziiIgT/M+giDY=";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "eurooffice-desktopeditors: unsupported platform ${stdenv.hostPlatform.system}");

  # The .deb's files as they are: no patching, stripping or wrapping of its bundled libraries
  unpacked = stdenv.mkDerivation {
    pname = "eurooffice-desktopeditors-unpacked";
    inherit version;
    src = fetchurl {
      url = "https://github.com/Euro-Office/DesktopEditors/releases/download/v${version}/euro-office-euro-office_${version}-0_${asset.arch}.deb";
      inherit (asset) hash;
    };
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r opt usr $out/
      runHook postInstall
    '';
    dontFixup = true;
  };
in
buildFHSEnv {
  pname = "eurooffice-desktopeditors";
  inherit version;
  # Its .deb, for bin/update-pkgs (src.url of each system)
  passthru.src = unpacked.src;

  # What the bundled Qt and Chromium link against or load (the .deb's Depends), and its launcher's tools
  targetPkgs =
    pkgs: with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      brotli
      bzip2.out # Its library (outputsToInstall: its tools only)
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gst_all_1.gst-libav
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-ugly
      gst_all_1.gstreamer
      gtk3
      krb5
      libdrm
      libGL
      libgbm
      libice
      libnotify
      libpulseaudio
      libva
      libx11
      libxcb
      libxcb-cursor
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxkbcommon
      libxrandr
      libxrender
      libxscrnsaver
      libxshmfence
      libsm
      libxtst
      nspr
      nss
      pango
      systemd # libudev
      wayland
      xdg-user-dirs # Its launcher: the templates folder, for "New document"...
      xdg-utils
      xkeyboard_config
      zlib
      zstd
    ];
  # Left out (their plugins aren't used): Qt's SQL drivers (libpq, ODBC, MySQL) and Quick3D

  runScript = "${unpacked}/usr/bin/euro-office-euro-office";
  # Libraries by file name too, not only by the soname the linker's cache indexes: Debian's libbz2 (libbz2.so.1.0,
  # its FFmpeg's: video in presentations) is nixpkgs' libbz2.so.1, whose /usr/lib has both names
  profile = ''
    export LD_LIBRARY_PATH=/usr/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
  '';

  # Its files where its launcher looks for them; fonts (above), mounted after the environment's own (/usr)
  extraBwrapArgs = [
    "--ro-bind ${unpacked}/opt/euro-office /opt/euro-office"
  ]
  ++ lib.optionals (fonts != [ ]) (
    [ "--tmpfs /usr/share/fonts" ]
    ++ lib.concatMap (font: [
      "--dir /usr/share/fonts/${baseNameOf font}"
      "--ro-bind-try ${font}/share/fonts /usr/share/fonts/${baseNameOf font}"
    ]) fonts
  );

  extraInstallCommands = ''
    mkdir -p $out/share
    ln -s ${unpacked}/usr/share/icons $out/share
    cp -r ${unpacked}/usr/share/applications $out/share
    substituteInPlace $out/share/applications/euro-office-euro-office.desktop \
      --replace-fail "/usr/bin/euro-office-euro-office" "$out/bin/eurooffice-desktopeditors"
  '';

  meta = {
    description = "Office suite for documents, spreadsheets, presentations and PDFs (Euro-Office, OnlyOffice's European fork)";
    homepage = "https://euro-office.nl/";
    downloadPage = "https://github.com/Euro-Office/DesktopEditors/releases";
    mainProgram = "eurooffice-desktopeditors";
    platforms = builtins.attrNames assets;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.agpl3Plus;
  };
}
