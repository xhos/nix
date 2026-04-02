{
  config,
  pkgs,
  ...
}: let
  proxy-1-ip = "40.233.88.40";
  proxy-2-ip = "89.168.83.242";
in {
  sops.secrets."env/proxy-failover" = {};

  networking.firewall.trustedInterfaces = ["wg0"];

  networking.wireguard.interfaces.wg0 = {
    mtu = 1408;
    ips = ["${config._enrai.config.tunnelIP}/24"];
    privateKeyFile = "/var/lib/wireguard/private.key";
    generatePrivateKeyFile = true;
    peers = [
      {
        publicKey = "4kdzVuqFfu8kEi1yE2DpRRkH5J32jmZnnyIAhqlbDmU=";
        endpoint = "${proxy-1-ip}:55055";
        allowedIPs = ["10.100.0.1/32"];
        persistentKeepalive = 25;
      }
      {
        publicKey = "mgfixeebDV6jGhYfU/fdBVIr/miiOf8KOzjBN2K/eT8=";
        endpoint = "${proxy-2-ip}:55055";
        allowedIPs = ["10.100.0.2/32"];
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.timers."vps-failover" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  systemd.services."vps-failover" = {
    serviceConfig = let
      cfg = {
        domain = config._enrai.config.publicDomain;
        primary = {
          ip = proxy-1-ip;
          wg = "10.100.0.1";
        };
        secondary = {
          ip = proxy-2-ip;
          wg = "10.100.0.2";
        };
      };

      failoverScript = pkgs.writeShellApplication {
        name = "vps-failover";
        runtimeInputs = with pkgs; [
          curl
          dig
          iputils
          jq
        ];

        text = ''
          # shellcheck disable=SC1091
          source ${config.sops.secrets."env/proxy-failover".path}

          current_ip=$(dig +short "${cfg.domain}" @1.1.1.1 | head -n1)

          check_vps() {
            ping -c 3 -W 2 "$1" >/dev/null 2>&1
          }

          update_dns() {
            local new_ip=$1

            record_id=$(curl -s -X GET \
              "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=${cfg.domain}&type=A" \
              -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
              -H "Content-Type: application/json" | jq -r '.result[0].id')

            curl -s -X PUT \
              "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_id" \
              -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
              -H "Content-Type: application/json" \
              --data "{\"type\":\"A\",\"name\":\"${cfg.domain}\",\"content\":\"$new_ip\",\"ttl\":120,\"proxied\":false}" >/dev/null
          }

          notify() {
            curl -s -X POST \
              "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
              -d chat_id="$TELEGRAM_CHAT_ID" \
              -d text="[vps-failover] $*" >/dev/null
          }

          primary_alive=false
          secondary_alive=false

          check_vps "${cfg.primary.wg}" && primary_alive=true
          check_vps "${cfg.secondary.wg}" && secondary_alive=true

          # failback to primary if it's alive and dns points elsewhere
          if [ "$primary_alive" = true ] && [ "$current_ip" != "${cfg.primary.ip}" ]; then
            update_dns "${cfg.primary.ip}"
            notify "failing back to primary (${cfg.primary.ip})"

          # failover to secondary if primary is dead
          elif [ "$primary_alive" = false ] && [ "$secondary_alive" = true ] && [ "$current_ip" = "${cfg.primary.ip}" ]; then
            update_dns "${cfg.secondary.ip}"
            notify "proxy-1 dead, failed over to proxy-2 (${cfg.secondary.ip})"

          # both dead
          elif [ "$primary_alive" = false ] && [ "$secondary_alive" = false ]; then
            notify "both vps dead :("
            exit 1
          fi

          echo "primary=$primary_alive secondary=$secondary_alive dns=$current_ip"
        '';
      };
    in {
      Type = "oneshot";
      ExecStart = "${failoverScript}/bin/vps-failover";
    };
  };
}
