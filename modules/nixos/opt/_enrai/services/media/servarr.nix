{
  lib,
  config,
  ...
}: {
  services = {
    prowlarr.enable = true;
    radarr.enable = true;
    bazarr.enable = true;
    flaresolverr.enable = true;
  };

  _enrai.exposedServices.prowlarr.port = config.services.prowlarr.settings.server.port;
  _enrai.exposedServices.radarr.port = config.services.radarr.settings.server.port;
  _enrai.exposedServices.bazarr.port = config.services.bazarr.listenPort;
  _enrai.exposedServices.flaresolverr.port = config.services.flaresolverr.port;

  users = let
    mediaServices = ["sonarr" "radarr" "bazarr" "prowlarr"];
  in {
    users = lib.genAttrs mediaServices (name: {
      isSystemUser = true;
      group = name;
      extraGroups = ["media"];
    });
    groups = lib.genAttrs (mediaServices ++ ["media"]) (_: {});
  };

  # unset dynamic user stuff which makes it difficult to persist
  systemd.services.prowlarr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "prowlarr";
    Group = "prowlarr";
  };

  systemd.tmpfiles.rules = [
    "d /storage/media 0775 root media -"
    "d /storage/media/anime 0775 root media -"
  ];
}
