{
  pkgs,
  config,
  ...
}: {
  _enrai.exposedServices.jellyfin = {
    exposed = true;
    amneziaAccessible = true;
    port = 8096;
  };
  _enrai.exposedServices.jellyseerr.port = config.services.jellyseerr.port;

  persist.dirs = [
    "/var/lib/jellyfin"
    "/var/cache/jellyfin"
  ];

  systemd.tmpfiles.rules = [
    "d /storage/media/cache 0755 root root -"
    "d /storage/media/cache/jellyfin 0755 jellyfin jellyfin -"
  ];

  services.jellyseerr.enable = true;

  services.jellyfin = {
    enable = true;
    cacheDir = "/storage/media/cache/jellyfin";
  };

  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

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
      jellyfin.extraGroups = [
        "video"
        "media"
      ];
      xhos.extraGroups = ["media"];
    };
  };
}
