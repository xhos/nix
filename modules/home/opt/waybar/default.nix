{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.bar == "waybar") {
    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
  };
}
