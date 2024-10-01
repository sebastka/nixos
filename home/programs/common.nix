{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    duf ldns nmap
    terraform ansible
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
