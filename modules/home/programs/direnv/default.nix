{ config, lib, ... }:

let
  cfg = config.programs.direnv;

  # export NAME=value, or the output of a command run when entering the directory (direnv reports a failure)
  exportLine =
    name: value:
    if lib.isString value then
      "export ${name}=${lib.escapeShellArg value}"
    else
      ''if _value="$(${value.command})"; then export ${name}="$_value"; else log_error ${lib.escapeShellArg "${name}: command failed: ${value.command}"}; fi'';
in
{
  # programs.direnv.directoryEnv."<directory, relative to ~>" = { NAME = "value"; NAME.command = "..."; }: its .envrc
  # exports them, for every project below too (source_up_if_exists below). Generated, so trusted without `direnv allow`.
  options.programs.direnv.directoryEnv = lib.mkOption {
    type =
      with lib.types;
      attrsOf (
        attrsOf (
          either str (submodule {
            options.command = lib.mkOption {
              type = str;
              description = "Command whose output is the value, run when entering the directory.";
            };
          })
        )
      );
    default = { };
    example = {
      "Dev/Work" = {
        DIGITALOCEAN_CONTEXT = "work";
        TOKEN.command = "secret-tool lookup service example";
      };
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
        text =
          lib.concatLines (lib.mapAttrsToList exportLine variables)
          + lib.optionalString (lib.any (value: !lib.isString value) (
            lib.attrValues variables
          )) "unset _value\n";
      }
    ) cfg.directoryEnv;
  };
}
