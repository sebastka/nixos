{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts # broad Unicode coverage, good base font set
    noto-fonts-cjk-sans # Chinese, Japanese, Korean
    noto-fonts-color-emoji # emoji
    font-awesome # icon font used by many apps and themes
  ];
}
