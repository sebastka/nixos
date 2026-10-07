{ config, lib, ... }:

let
  cfg = config.programs.direnv;
in
{
  # programs.direnv.directoryEnv."<directory, relative to ~>" = { NAME = "value"; }: its .envrc exports them, for every
  # project below too (source_up_if_exists below). Generated, so trusted without `direnv allow`.
  options.programs.direnv.directoryEnv = lib.mkOption {
    type = with lib.types; attrsOf (attrsOf str);
    default = { };
    example = {
      "Dev/Work".DIGITALOCEAN_CONTEXT = "work";
    };
    description = "Environment variables of a directory and its subdirectories (a generated .envrc).";
  };

  config = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # Before each .envrc: the next .envrc above it, if any (e.g. ~/Dev/Work/.envrc for every work project), so
      # projects get it without committing source_up. The project's own .envrc runs after, and can override it.
      stdlib = ''
        source_up_if_exists
      '';
      config.whitelist.exact = lib.mapAttrsToList (
        directory: _: "${config.home.homeDirectory}/${directory}/.envrc"
      ) cfg.directoryEnv;
    };

    home.file = lib.mapAttrs' (
      directory: variables:
      lib.nameValuePair "${directory}/.envrc" {
        text = lib.concatLines (
          lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") variables
        );
      }
    ) cfg.directoryEnv;
  };
}
