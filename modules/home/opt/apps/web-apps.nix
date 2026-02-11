{
  config,
  lib,
  pkgs,
  ...
}: let
  mkWebAppIcon = {
    name,
    url,
    hash,
  }:
    pkgs.fetchurl {
      name = "${name}-icon";
      inherit url hash;
    };

  webAppIcons = lib.optionalAttrs (config.headless != true) {
    yandex-music = mkWebAppIcon {
      name = "yandex-music";
      url = "https://i.imgur.com/tJuGyOB.png";
      hash = "sha256-VE/He5iwrH+oSAn4sN467h2FBweZj3Fw5NFBoi0iXL4=";
    };
  };

  mkWebApp = {
    name,
    url,
    iconName ? null,
  }: {
    name = name;
    genericName = name;
    exec = "${pkgs.chromium}/bin/chromium --app=\"${url}\" --enable-features=UseOzonePlatform --ozone-platform=wayland";
    icon =
      if iconName != null
      then webAppIcons.${iconName}
      else "chromium";
    terminal = false;
    startupNotify = true;
    categories = ["Application"];
  };
in {
  config = lib.mkIf (config.headless != true) {
    xdg.desktopEntries = {
      yandex-music = mkWebApp {
        name = "Yandex Music";
        url = "https://next.music.yandex.ru";
        iconName = "yandex-music";
      };
    };
  };
}
