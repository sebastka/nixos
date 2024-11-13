{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    duf ldns nmap whois
    terraform ansible
    terragrunt
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
