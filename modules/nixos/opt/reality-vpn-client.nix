{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.reality-vpn-client;
in {
  options.reality-vpn-client = {
    enable = lib.mkEnableOption "VLESS+Reality client that tunnels all traffic through proxy-1 (for bypassing restrictive networks, e.g. China)";
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "40.233.109.227";
      description = "proxy-1 public IP";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      "vpn/singbox/uuid".owner = "sing-box";
      "vpn/singbox/reality-public-key".owner = "sing-box";
      "vpn/singbox/short-id".owner = "sing-box";
    };

    services.sing-box = {
      enable = true;
      settings = {
        log.level = "warn";
        dns = {
          servers = [
            {
              type = "https";
              tag = "remote";
              server = "1.1.1.1";
              detour = "reality-out";
            }
            {
              type = "local";
              tag = "local";
            }
          ];
          final = "remote";
          strategy = "ipv4_only";
        };
        inbounds = [
          {
            type = "tun";
            tag = "tun-in";
            interface_name = "singbox0";
            address = ["172.19.0.1/30"];
            auto_route = true;
            strict_route = true;
            stack = "system";
          }
        ];
        outbounds = [
          {
            type = "vless";
            tag = "reality-out";
            server = cfg.endpoint;
            server_port = 443;
            uuid._secret = config.sops.secrets."vpn/singbox/uuid".path;
            flow = "xtls-rprx-vision";
            tls = {
              enabled = true;
              server_name = "www.cloudflare.com";
              utls = {
                enabled = true;
                fingerprint = "chrome";
              };
              reality = {
                enabled = true;
                public_key._secret = config.sops.secrets."vpn/singbox/reality-public-key".path;
                short_id._secret = config.sops.secrets."vpn/singbox/short-id".path;
              };
            };
          }
          {
            type = "direct";
            tag = "direct";
          }
        ];
        route = {
          rules = [
            {
              action = "sniff";
            }
            {
              ip_is_private = true;
              outbound = "direct";
            }
            {
              ip_cidr = ["${cfg.endpoint}/32"];
              outbound = "direct";
            }
          ];
          final = "reality-out";
          auto_detect_interface = true;
        };
      };
    };

    systemd.services.sing-box = {
      wantedBy = lib.mkForce [];
      serviceConfig = {
        AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE"];
      };
    };

    security.sudo.extraRules = [
      {
        groups = ["wheel"];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl start sing-box";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/systemctl stop sing-box";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/systemctl restart sing-box";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "vpn" ''
        case "''${1:-}" in
          up|on|start)    sudo systemctl start sing-box ;;
          down|off|stop)  sudo systemctl stop sing-box ;;
          restart)        sudo systemctl restart sing-box ;;
          status|"")      systemctl is-active sing-box && ${pkgs.iproute2}/bin/ip -br addr show singbox0 2>/dev/null ;;
          log|logs)       journalctl -u sing-box -f ;;
          ip)             ${pkgs.curl}/bin/curl -s https://ifconfig.me; echo ;;
          *) echo "usage: vpn {up|down|restart|status|log|ip}"; exit 1 ;;
        esac
      '')
    ];
  };
}
