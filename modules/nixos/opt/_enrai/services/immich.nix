{config, ...}: {
  _enrai.exposedServices.photos.port = config.services.immich.port;
  _enrai.backup.services.immich.paths = ["${config.services.immich.mediaLocation}"];

  persist.dirs = [
    "/var/lib/redis-immich"
    "/var/cache/immich"
  ];

  services.immich = {
    enable = true;
    mediaLocation = "/storage/photos";
    host = "127.0.0.1";
    settings.server.externalDomain = "https://photos.lab.xhos.dev";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/redis-immich 0750 redis-immich redis-immich -"
    "d /var/cache/immich 0750 immich immich -"
  ];
}
