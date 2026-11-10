{ lib, ... }:

{
  # Packages no binary cache has for every desktop (aarch64: none of ours, nor cache.nixos.org for some of unstable's),
  # so compiled on the host: Tern (./tern.nix), and Node.js with what needs it (modules/home/programs: node, Renovate
  # in ops, the Copilot CLI in coding-agents). Off on a host that shouldn't build them, e.g. boreas while it has no
  # binary cache.
  options.desktop.uncachedPackages.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Install the desktop packages compiled locally where no binary cache has them.";
  };
}
