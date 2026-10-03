{ pkgs, ... }:

{
  imports = [
    ../../modules/home/programs/ops
    ../../modules/home/programs/vscode
  ];

  home.packages = with pkgs; [
    kdePackages.kate
    thunderbird
    bitwarden-desktop
  ];
}
