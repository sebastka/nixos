{
  pkgs,
  ...
}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim nano
    unzip
    wget curl dig
    screen
    git jq
    sysstat lm_sensors
  ];
}
