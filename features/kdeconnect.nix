{
  flake.modules.nixos.kdeconnect = {
    programs.kdeconnect.enable = true;
  };

  flake.modules.homeManager.kdeconnect = {
    config,
    lib,
    pkgs,
    ...
  }: {
    services.kdeconnect = {
      enable = true;
      package = pkgs.valent;
    };

    hyprland.execOnce =
      lib.mkIf (config.wm == "hyprland")
      ["${lib.getExe pkgs.valent} --gapplication-service"];
  };
}
