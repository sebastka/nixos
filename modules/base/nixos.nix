{
  lib,
  ...
}: {
  # customise /etc/nix/nix.conf declaratively via `nix.settings`
  # nix.package = pkgs.nixFlakes;
  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
