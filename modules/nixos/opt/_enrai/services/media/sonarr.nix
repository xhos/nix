{config, ...}: let
  port = toString config.services.sonarr.settings.server.port;
  secret = name: config.sops.secrets."media/${name}".path;
in {
  sops.secrets."media/api/sonarr" = {group = "media"; mode = "0440";};
  sops.secrets."media/password/sonarr" = {group = "media"; mode = "0440";};

  persist.dirs = ["/var/lib/sonarr"];

  services.sonarr.enable = true;
  services.sonarr.apiKeyFile = secret "api/sonarr";
  _enrai.exposedServices.sonarr.port = config.services.sonarr.settings.server.port;

  systemd.services.sonarr.environment = {
    SONARR__AUTH__METHOD = "Forms";
    SONARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
  };

  systemd.tmpfiles.rules = [
    "d /storage/media/anime 0775 root media -"
  ];

  services.declarr.config.sonarr = {
    declarr = {
      type = "sonarr";
      url = "http://127.0.0.1:${port}";
    };

    config.host = {
      apiKey = secret "api/sonarr";
      authenticationMethod = "forms";
      authenticationRequired = "disabledForLocalAddresses";
      username = "xhos";
      password = secret "password/sonarr";
      passwordConfirmation = secret "password/sonarr";
    };

    regexPatterns = {
      "Russian Subs" = "(?i)\\b(anilib|rus(sian)?)\\b";
      "Anime Raws" = "(?i)\\b(raw|raws)\\b";
    };

    customFormat = {
      "Russian Subs".conditions = [{
        name = "Russian Subs";
        type = "release_title";
        pattern = "Russian Subs";
        negate = false;
        required = true;
      }];

      "Dubs Only".conditions = [
        {name = "English Audio"; type = "language"; language = "english"; negate = false; required = true;}
        {name = "Not Japanese Audio"; type = "language"; language = "japanese"; negate = true; required = true;}
      ];

      "Anime Dual Audio".conditions = [{
        name = "Dual Audio";
        type = "release_title";
        pattern = "Dual Audio";
        negate = false;
        required = true;
      }];

      "Anime Raws".conditions = [{
        name = "Anime Raws";
        type = "release_title";
        pattern = "Anime Raws";
        negate = false;
        required = true;
      }];
    };

    downloadClient.qBittorrent = {
      implementation = "QBittorrent";
      fields = {
        host = config.vpnNamespaces.proton.namespaceAddress;
        port = 8080;
        username = "admin";
        password = config.sops.secrets."media/password/qbit".path;
      };
    };

    rootFolder = ["/storage/media/anime"];

    qualityProfile."1080p Balanced" = {
      upgradesAllowed = true;
      upgradeUntilScore = 10000;
      minCustomFormatScore = 0;
      custom_formats = [
        {name = "Russian Subs"; score = 800;}
        {name = "Dubs Only"; score = 1500;}
        {name = "Anime Dual Audio"; score = 2000;}
        {name = "Anime Raws"; score = -10000;}
      ];
    };
  };
}
