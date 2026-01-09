{config, ...}: {
  persist.dirs = ["/var/lib/sonarr"];
  services.sonarr.enable = true;
  _enrai.exposedServices.sonarr.port = config.services.sonarr.settings.server.port;

  services.recyclarr = {
    enable = true;
    schedule = "daily";

    configuration = {
      sonarr.anime-sonarr-v4 = {
        base_url = "http://127.0.0.1:${toString config.services.sonarr.settings.server.port}";
        api_key = "103b0d5df72a4624b2a9e43fbaaa894a";

        include = [
          {template = "sonarr-quality-definition-anime";}
          {template = "sonarr-v4-quality-profile-anime";}
          {template = "sonarr-v4-custom-formats-anime";}
        ];

        custom_formats = [
          {
            trash_ids = [
              "026d5aadd1a6b4e550b134cb6c72b3ca" # Uncensored
            ];
            assign_scores_to = [
              {
                name = "Remux-1080p - Anime";
                score = 0;
              }
            ];
          }

          {
            trash_ids = [
              "b2550eb333d27b75833e25b8c2557b38" # 10bit
            ];
            assign_scores_to = [
              {
                name = "Remux-1080p - Anime";
                score = 0;
              }
            ];
          }

          {
            trash_ids = [
              "418f50b10f1907201b6cfdf881f467b7" # Anime Dual Audio
            ];
            assign_scores_to = [
              {
                name = "Remux-1080p - Anime";
                score = 0;
              }
            ];
          }
        ];
      };
    };
  };
}
