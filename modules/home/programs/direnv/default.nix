{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Before each .envrc: the next .envrc above it, if any (e.g. ~/Dev/Work/.envrc for every work project), so
    # projects get it without committing source_up. The project's own .envrc runs after, and can override it.
    stdlib = ''
      source_up_if_exists
    '';
  };
}
