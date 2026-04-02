{config, ...}: {
  sops.secrets."env/wled-album-sync" = {};

  services.wled-album-sync = {
    enable = true;
    wledUrl = "http://10.0.0.31";
    port = 9123;

    homeAssistant = {
      url = "http://${config._enrai.config.enraiLocalIP}:8123";
      entity = "media_player.yandex_station_xk0000000000000286720000e2296918";
    };

    spotify.clientId = "27bab5ed9bd8438a801980f52ba273ce";

    envFile = config.sops.secrets."env/wled-album-sync".path;
  };
}
