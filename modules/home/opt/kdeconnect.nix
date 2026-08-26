{
  pkgs,
  lib,
  config,
  ...
}: {
  options.modules.kdeconnect.enable = lib.mkEnableOption "kdeconnect daemon (valent)";

  config = lib.mkIf config.modules.kdeconnect.enable {
    services.kdeconnect = {
      enable = true;
      package = pkgs.valent;
    };

    hyprland.execOnce =
      lib.mkIf (config.wm == "hyprland")
      ["${lib.getExe pkgs.valent} --gapplication-service"];
  };
}
