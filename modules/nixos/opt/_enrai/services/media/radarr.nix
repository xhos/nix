{config, ...}: let
  port = toString config.services.radarr.settings.server.port;
  secret = name: config.sops.secrets."media/${name}".path;
in {
  sops.secrets."media/api/radarr" = {group = "media"; mode = "0440";};
  sops.secrets."media/password/radarr" = {group = "media"; mode = "0440";};

  persist.dirs = ["/var/lib/radarr"];

  services.radarr.enable = true;
  services.radarr.apiKeyFile = secret "api/radarr";
  _enrai.exposedServices.radarr.port = config.services.radarr.settings.server.port;

  systemd.services.radarr.environment = {
    RADARR__AUTH__METHOD = "Forms";
    RADARR__AUTH__REQUIRED = "DisabledForLocalAddresses";
  };

  systemd.tmpfiles.rules = [
    "d /storage/media/movies 0775 root media -"
  ];

  services.declarr.config.radarr = {
    declarr = {
      type = "radarr";
      url = "http://127.0.0.1:${port}";
    };

    config.host = {
      apiKey = secret "api/radarr";
      authenticationMethod = "forms";
      authenticationRequired = "disabledForLocalAddresses";
      username = "xhos";
      password = secret "password/radarr";
      passwordConfirmation = secret "password/radarr";
    };

    regexPatterns = {
      "Russian Subs" = "(?i)\\b(rus(sian)?[\\s._-]?sub|sub[\\s._-]?rus)\\b";
    };

    customFormat = {
      "Russian Subs".conditions = [{
        name = "Russian Subs";
        type = "release_title";
        pattern = "Russian Subs";
        negate = false;
        required = true;
      }];

      "Russian Audio".conditions = [{
        name = "Russian Audio";
        type = "language";
        language = "russian";
        negate = false;
        required = true;
      }];

      "Dual Audio".conditions = [
        {name = "English Audio"; type = "language"; language = "english"; negate = false; required = true;}
        {name = "Russian Audio"; type = "language"; language = "russian"; negate = false; required = true;}
      ];

      "Remux".conditions = [{
        name = "Remux";
        type = "release_title";
        pattern = "Remux";
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

    rootFolder = ["/storage/media/movies"];

    qualityProfile."1080p Balanced" = {
      upgradesAllowed = true;
      upgradeUntilScore = 10000;
      minCustomFormatScore = 0;
      custom_formats = [
        {name = "Russian Subs"; score = 800;}
        {name = "Russian Audio"; score = 1500;}
        {name = "Dual Audio"; score = 2000;}
        {name = "Remux"; score = -10000;}
      ];
    };
  };
}
