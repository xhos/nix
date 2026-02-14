{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [inputs.logi-hypr.homeManagerModules.default];

  config = lib.mkIf (config.wm == "hyprland") {
    wayland.windowManager.hyprland.settings.exec-once = ["logi-hypr-run"];

    programs.logi-hypr = {
      enable = true;

      gesture.commands = {
        tap = "hyprctl dispatch togglespecialworkspace";
        left = "playerctl --player=spotify previous";
        right = "playerctl --player=spotify next";
        up = "hyprctl dispatch workspace m-1";
        down = "hyprctl dispatch workspace m+1";
      };

      scroll.rules = [
        {
          window = "Spotify";
          scrollRightCommands = [
            "volume-script --inc"
          ];
          scrollLeftCommands = [
            "volume-script --dec"
          ];
        }
      ];
    };
  };
}
