{
  config,
  lib,
  ...
}: {
  stylix = lib.mkIf (config.wm == "niri") {
    opacity.terminal = 1.0;
  };
}
