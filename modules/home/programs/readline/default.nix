{ ... }:

{
  # ~/.config/inputrc (INPUTRC is set through home.preferXdgDirectories).
  # Readline is used by bash, psql, sqlite3, gdb and the basic Python REPL, not by zsh (zle).
  programs.readline = {
    enable = true;
    variables = {
      completion-ignore-case = true;     # Tab completion ignores case
      show-all-if-ambiguous = true;      # List all matches on the first Tab
      colored-stats = true;              # Color completion candidates like `ls`
      colored-completion-prefix = true;  # Highlight the already typed part of each candidate
      mark-symlinked-directories = true; # Add / to completed symlinks to directories
      bell-style = "none";
    };
    bindings = {
      # Up/Down: search the history for commands starting with what is already typed
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
    };
  };
}
