{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [inputs.logi-hypr.homeManagerModules.default];

  config = lib.mkIf (config.wm == "hyprland") {
    hyprland.execOnce = ["logi-hypr-run"];

    programs.logi-hypr = {
      enable = true;

      gesture.commands = {
        tap = ''hyprctl dispatch "hl.dsp.workspace.toggle_special()"'';
        left = "playerctl --player=spotify previous";
        right = "playerctl --player=spotify next";
        up = ''hyprctl dispatch "hl.dsp.focus({workspace = [[m-1]]})"'';
        down = ''hyprctl dispatch "hl.dsp.focus({workspace = [[m+1]]})"'';
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
