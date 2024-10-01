{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ungoogled-chromium
    thunderbird
    bitwarden-desktop
    telegram-desktop
    libreoffice-qt hunspell hunspellDicts.en_US hunspellDicts.nb_NO hunspellDicts.fr-classique
    gimp-with-plugins
    inkscape-with-extensions
  ];

  programs.firefox.enable = true;

  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
    userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'Fira Code', 'monospace'";
    };
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      github.copilot
      yzhang.markdown-all-in-one
      mechatroner.rainbow-csv
    ];
  };
}
