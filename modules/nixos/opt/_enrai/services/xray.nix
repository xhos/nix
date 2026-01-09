{ config, ... }:
{
  sops.secrets."vpn/xray" = { };

  _enrai.exposedServices.vpn = {
    port = 10808;
    exposed = true;
  };

  services.xray = {
    enable = true;
    settingsFile = config.sops.secrets."vpn/xray".path;
  };
}
