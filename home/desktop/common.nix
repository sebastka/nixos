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
    deluge
    inkscape-with-extensions
    awscli2 cli53
  ];

  programs.firefox.enable = true;

  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
    userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'Fira Code', 'monospace'";
      "github.copilot.enable" = {
        "*" = true;
        "yaml" = true;
        "plaintext" = true;
        "markdown" = true;
      };
      "terraform.languageServer.terraform.timeout" = "2";
    };
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      github.copilot
      yzhang.markdown-all-in-one
      mechatroner.rainbow-csv
      hashicorp.terraform
    ];
  };
}
