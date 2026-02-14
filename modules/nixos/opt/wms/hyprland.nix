{
  lib,
  config,
  ...
}: {
  programs.hyprland = lib.mkIf (config.wm == "hyprland") {
    enable = true;
    withUWSM = true;
  };
}
