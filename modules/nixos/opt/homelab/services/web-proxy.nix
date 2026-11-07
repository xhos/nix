{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.web-proxy;
  domain = config.homelab.config.domain;
  host = "${cfg.subdomain}.${domain}";
  port = 8445;
in {
  options.homelab.web-proxy = {
    enable = lib.mkEnableOption "password-protected https forward proxy on :443 (via sslh sni)";
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = "relay";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.homelab.reality-vpn.enable;
        message = "web-proxy rides on the sslh/sing-box setup from reality-vpn";
      }
    ];

    sops.secrets."vpn/web-proxy/password".owner = "sing-box";

    # must win over the catch-all tls rule that goes to caddy
    services.sslh.settings.protocols = lib.mkBefore [
      {
        name = "tls";
        host = "127.0.0.1";
        port = toString port;
        sni_hostnames = [host];
      }
    ];

    services.sing-box.settings.inbounds = [
      {
        type = "http";
        tag = "web-proxy-in";
        listen = "127.0.0.1";
        listen_port = port;
        users = [
          {
            username = "xhos";
            password._secret = config.sops.secrets."vpn/web-proxy/password".path;
          }
        ];
        tls = {
          enabled = true;
          server_name = host;
          certificate_path = "/var/lib/acme/${domain}/fullchain.pem";
          key_path = "/var/lib/acme/${domain}/key.pem";
        };
      }
    ];

    users.users.sing-box.extraGroups = [config.services.caddy.group];
    security.acme.certs.${domain}.reloadServices = ["sing-box.service"];
  };
}
