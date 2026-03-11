{
  config,
  lib,
  ...
}: {
  options.obs.enable = lib.mkEnableOption "OBS Studio for screen recording";

  config = lib.mkIf config.obs.enable {
    programs.obs-studio = {
      enable = true;
      # enableVirtualCamera = true;
    };
  };
}
