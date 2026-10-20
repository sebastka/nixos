{ pkgs, ... }:

let
  # Wine's free versions of Windows' other fonts (LGPL): Symbol, Wingdings, Marlett, MS Sans Serif, Courier, Fixedsys,
  # Small Fonts, System. Not its Tahoma nor Webdings: Microsoft's own are in corefonts (two fonts of the same name:
  # either one used).
  wine-fonts = pkgs.runCommand "wine-fonts-${pkgs.winePackages.fonts.version}" { } ''
    mkdir -p $out/share/fonts/truetype
    cp ${pkgs.winePackages.fonts}/share/fonts/truetype/*.ttf $out/share/fonts/truetype
    rm $out/share/fonts/truetype/{tahoma,tahomabd,webdings}.ttf
  '';
in
{
  fonts.packages = with pkgs; [
    noto-fonts # broad Unicode coverage, good base font set
    noto-fonts-cjk-sans # Chinese, Japanese, Korean
    noto-fonts-color-emoji # emoji
    font-awesome # icon font used by many apps and themes
    hack-font # The monospace font (terminals, editors): Plasma's default, also set for Cinnamon (modules/nixos/cinnamon)
    open-sans # OnlyOffice's default (bundled in it), also in the other apps opening its documents
    # Windows' fonts, for documents made with them (Office): Microsoft's (unfree) Arial, Times New Roman, Courier New,
    # Verdana, Georgia, Tahoma... (corefonts), Calibri, Cambria, Consolas... (vista-fonts), then Wine's (above)
    corefonts
    vista-fonts
    wine-fonts
  ];
}
