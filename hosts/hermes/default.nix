{
  pkgs, 
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/nb_NO.nix
  ];

  networking.hostName = "hermes";
  networking.domain = "home.karlsen.fr";

  system.stateVersion = "24.05";
}
