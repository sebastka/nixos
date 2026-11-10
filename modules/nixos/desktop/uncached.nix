{ lib, ... }:

{
  # Packages no binary cache has for every desktop (aarch64: none of ours), so compiled on the host: Tern (./tern.nix,
  # a flake input). Off on a host that shouldn't build them, e.g. boreas while it has no binary cache.
  options.desktop.uncachedPackages.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Install the desktop packages compiled locally where no binary cache has them.";
  };
}
