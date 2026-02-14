{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.wm == "hyprland" && config.hyprland.hyprspace.enable) {
    wayland.windowManager.hyprland = {
      plugins = [pkgs.hyprlandPlugins.hyprspace];
      settings = {
        bind = [
          "SUPER, Tab, overview:toggle"
          "SUPERSHIFT, TAB, overview:toggle, all"
        ];

        plugin = [
          {
            overview = {
              affectStrut = false;
              hideTopLayers = true;
              panelHeight = 250;
              showEmptyWorkspace = false;
              showNewWorkspace = true;
              disableBlur = true;
            };
          }
        ];
      };
    };
  };
}
