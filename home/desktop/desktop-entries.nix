{
  pkgs,
  ...
}: {
  xdg.desktopEntries = {
    YNAB = {
      name = "YNAB";
      genericName = "You Need A Budget";
      comment = "Personal budgeting software";
      type = "Application";
      exec = "${pkgs.ungoogled-chromium}/bin/chromium --app=https://app.ynab.com";
      terminal = false;
      categories = [ "Application" "Office" ];
      icon = "${../../assets/icons/ynab.svg}";
      #mimeType = [ "text/html" "text/xml" ];
    };
    Paperless = {
      name = "Paperless";
      genericName = "Paperless-ngx";
      comment = "Document Management System";
      type = "Application";
      exec = "${pkgs.ungoogled-chromium}/bin/chromium --app=https://paperless.homeswarm.atlas.home.karlsen.fr";
      terminal = false;
      categories = [ "Application" "Office" ];
      icon = "${../../assets/icons/paperless.svg}";
      #mimeType = [ "text/html" "text/xml" ];
    };
  };
}
