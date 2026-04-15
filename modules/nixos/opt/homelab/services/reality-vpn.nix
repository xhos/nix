{
  config,
  lib,
  ...
}: {
  options.homelab.reality-vpn.enable = lib.mkEnableOption "VLESS+Reality GFW-resistant entry point (fronted by sslh on :443, sharing with Caddy)";

  config = lib.mkIf config.homelab.reality-vpn.enable {
    sops.secrets = {
      "vpn/singbox/uuid".owner = "sing-box";
      "vpn/singbox/reality-private-key".owner = "sing-box";
      "vpn/singbox/short-id".owner = "sing-box";
    };

    services.sslh = {
      enable = true;
      method = "ev";
      listenAddresses = ["0.0.0.0" "[::]"];
      port = 443;
      settings.protocols = [
        {
          name = "tls";
          host = "127.0.0.1";
          port = "8444";
          sni_hostnames = ["www.cloudflare.com"];
        }
        {
          name = "tls";
          host = "127.0.0.1";
          port = "8443";
        }
      ];
    };

    services.sing-box = {
      enable = true;
      settings = {
        log.level = "warn";
        inbounds = [
          {
            type = "vless";
            tag = "vless-in";
            listen = "127.0.0.1";
            listen_port = 8444;
            users = [
              {
                uuid._secret = config.sops.secrets."vpn/singbox/uuid".path;
                flow = "xtls-rprx-vision";
              }
            ];
            tls = {
              enabled = true;
              server_name = "www.cloudflare.com";
              reality = {
                enabled = true;
                handshake = {
                  server = "www.cloudflare.com";
                  server_port = 443;
                };
                private_key._secret = config.sops.secrets."vpn/singbox/reality-private-key".path;
                short_id = [
                  {_secret = config.sops.secrets."vpn/singbox/short-id".path;}
                ];
              };
            };
          }
        ];
        outbounds = [
          {
            type = "direct";
            tag = "direct";
          }
        ];
      };
    };
  };
}
