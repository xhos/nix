{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.obs.enable = lib.mkEnableOption "OBS Studio for screen recording";

  config = lib.mkIf config.modules.obs.enable {
    # home.packages = [pkgs.droidcam];

    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [ droidcam-obs ];
    };
  };
}
