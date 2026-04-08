{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  config = lib.mkIf (config.wm == "hyprland") {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      plugins = [
        # inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
        # inputs.hyprsplit.packages.${pkgs.system}.hyprsplit
        inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors
      ];
      # plugins = with pkgs.hyprlandPlugins; [
      #   inputs.hyprsplit.packages.${pkgs.stdenv.hostPlatform.system}.hyprsplit
      #   inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors
      #   # hyprsplit
      #   # hypr-dynamic-cursors
      #   # hyprgrass
      # ];

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
