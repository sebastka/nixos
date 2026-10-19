{ ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$hostname$directory$git_branch$git_status$cmd_duration$character";
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol$hostname]($style):";
        ssh_symbol = "🌐 "; # Over SSH only: a remote shell
        style = "bold blue";
      };
      # $ instead of starship's ❯ (escaped: $ starts a variable): green, red after a failed command
      character = {
        success_symbol = "[\\$](bold green)";
        error_symbol = "[\\$](bold red)";
      };
    };
  };
}
