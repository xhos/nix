{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.stylix.homeModules.stylix];

  stylix = lib.mkIf (config.headless != true) {
    enable = true;
    polarity = "dark";

    cursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 24;
    };

    icons = {
      enable = true;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
      package = pkgs.papirus-icon-theme;
    };

    targets = {
      zed.enable = false;
      firefox.enable = false;
      spicetify.enable = true;
      hyprland.enable = false;
      hyprland.hyprpaper.enable = true;
      hyprlock.enable = false;
      mako.enable = false;
      rofi.enable = false;
      nixcord.enable = false;
      vencord.enable = false;
      vesktop.enable = false;
      kde.enable = false;
      waybar.enable = false;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Mono";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };
}
