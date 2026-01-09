{
  pkgs,
  config,
  lib,
  ...
}: {
  _enrai.exposedServices.jellyfin = {
    port = 8096;
    exposed = true;
  };

  persist.dirs = ["/var/lib/private/jellyseerr"];
  _enrai.exposedServices.jellyseerr = {
    port = config.services.jellyseerr.port;
    exposed = true;
  };

  services.jellyseerr.enable = true;


  services.jellyfin = {
    enable = true;
    cacheDir = "/storage/media/cache/jellyfin";
  };

  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables = {LIBVA_DRIVER_NAME = "iHD";};

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };

  users = {
    groups.media = {};
    users = {
      jellyfin.extraGroups = ["video" "media"];
      xhos.extraGroups = ["media"];
    };
  };
}
