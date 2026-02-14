{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.wm == "hyprland") {
    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      plugins = with pkgs.hyprlandPlugins; [
        hypr-dynamic-cursors
        hyprsplit
        # hyprgrass
      ];

      xwayland.enable = true;
    };

    services.hyprpaper.enable = true;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config.common.default = "*";
      configPackages = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = ["graphical-session-pre.target"];
      };
    };
  };
}
