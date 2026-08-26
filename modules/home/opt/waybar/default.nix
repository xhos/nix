{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.bar == "waybar") {
    hyprland.execOnce = lib.mkIf (config.wm == "hyprland") ["waybar"];
    programs.waybar.enable = true;
  };
}
