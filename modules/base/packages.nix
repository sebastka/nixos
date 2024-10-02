{
  pkgs,
  ...
}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim nano
    wget curl dig
    screen
    git jq
    htop sysstat lm_sensors
  ];
}
