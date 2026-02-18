{config, lib, ...}: let
  secret = name: config.sops.secrets."media/${name}".path;
  port = toString config.services.prowlarr.settings.server.port;
in {
  sops.secrets."media/api/prowlarr" = {group = "media"; mode = "0440";};
  sops.secrets."media/password/prowlarr" = {group = "media"; mode = "0440";};
  sops.secrets."media/password/rutracker" = {group = "media"; mode = "0440";};

  persist.dirs = ["/var/lib/prowlarr"];

  services.prowlarr.enable = true;
  services.prowlarr.apiKeyFile = secret "api/prowlarr";
  _enrai.exposedServices.prowlarr.port = config.services.prowlarr.settings.server.port;

  # unset dynamic user stuff which makes it difficult to persist
  systemd.services.prowlarr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "prowlarr";
    Group = "prowlarr";
  };
  systemd.services.prowlarr.environment = {
    PROWLARR__AUTH__METHOD = "Forms";
    PROWLARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
  };

  services.declarr.config.prowlarr = {
    declarr = {
      type = "prowlarr";
      url = "http://127.0.0.1:${port}";
    };

    config.host = {
      apiKey = secret "api/prowlarr";
      authenticationMethod = "forms";
      authenticationRequired = "disabledForLocalAddresses";
      username = "xhos";
      password = secret "password/prowlarr";
      passwordConfirmation = secret "password/prowlarr";
    };

    appProfile.Standard = {
      enableRss = true;
      enableAutomaticSearch = true;
      enableInteractiveSearch = true;
      minimumSeeders = 1;
    };

    applications = {
      Sonarr = {
        implementation = "Sonarr";
        syncLevel = "fullSync";
        fields = {
          baseUrl = "http://127.0.0.1:${toString config.services.sonarr.settings.server.port}";
          apiKey = secret "api/sonarr";
        };
      };
      Radarr = {
        implementation = "Radarr";
        syncLevel = "fullSync";
        fields = {
          baseUrl = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";
          apiKey = secret "api/radarr";
        };
      };
    };

    indexer = {
      "Nyaa.si" = {
        indexerName = "Nyaa.si";
        implementation = "Cardigann";
        appProfileId = "Standard";
        fields.definitionFile = "nyaasi";
      };
      "RuTracker.org" = {
        indexerName = "RuTracker.org";
        appProfileId = "Standard";
        fields = {
          username = "xhos";
          password = secret "password/rutracker";
        };
        tags = ["FlareSolverr"];
      };
    };

    indexerProxy.FlareSolverr = {
      implementation = "FlareSolverr";
      fields = {
        host = "http://localhost:${toString config.services.flaresolverr.port}/";
        requestTimeout = 60;
      };
      tags = ["FlareSolverr"];
    };
  };
}
