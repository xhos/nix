{config, ...}: {
  _enrai.exposedServices.timeline.port = config.services.dawarich.webPort;

  sops.secrets."passwords/dawarich" = {};

  persist.dirs = [
    "/var/cache/dawarich"
    "/var/lib/redis-dawarich"
    "/var/lib/dawarich"
  ];

  systemd.tmpfiles.rules = [
    "d /var/cache/dawarich 0750 dawarich dawarich -"
    "d /var/lib/redis-dawarich 0750 redis-dawarich redis-dawarich -"
    "d /var/lib/dawarich 0750 dawarich dawarich -"
  ];

  services.dawarich = {
    enable = true;
    webPort = 7000;
    localDomain = "timeline." + config._enrai.config.localDomain;
    secretKeyBaseFile = config.sops.secrets."passwords/dawarich".path;
    configureNginx = false;
  };
}
