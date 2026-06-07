{ ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$hostname$directory$git_branch$git_status$cmd_duration$character";
      hostname = {
        ssh_only = false;
        format = "[$hostname]($style):";
        style = "bold blue";
      };
    };
  };
}
