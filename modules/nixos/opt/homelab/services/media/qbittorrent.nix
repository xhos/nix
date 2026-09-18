{
  config,
  lib,
  pkgs,
  ...
}: {
  options.homelab.media.qbittorrent.enable = lib.mkEnableOption "qbittorrent with VPN confinement";

  config = lib.mkIf config.homelab.media.qbittorrent.enable {
    # create the downloads dir
    systemd.tmpfiles.rules = ["d /media/downloads 0775 root media -"];

    # all torrent traffic goes through proton vpn
    systemd.services.qbittorrent.vpnConfinement = {
      enable = true;
      vpnNamespace = "proton";
    };

    homelab.exposedServices.qbittorrent = {
      port = config.services.qbittorrent.webuiPort;
      upstream = config.vpnNamespaces.proton.namespaceAddress;
      dashboard.group = "media";
    };

    services.qbittorrent = {
      enable = true;
      user = "qbittorrent";
      group = "media";

      serverConfig = {
        LegalNotice.Accepted = true;
        BitTorrent.Session.DefaultSavePath = "/media/downloads";
        # port comes from proton nat-pmp, not upnp
        Preferences.Connection.UPnP = false;
        Preferences.WebUI = {
          Address = "0.0.0.0";
          # natpmp loop talks to the api from inside the namespace
          LocalHostAuth = false;
          Username = "admin";
          # https://gist.github.com/hastinbe/8b8d247f17481cfc262a98d661bc0fd5
          Password_PBKDF2 = "@ByteArray(cWgbdiY0hx3ipPWL3nGZBg==:RlTSPXDqYIbTTw0Hr2EzSh56H/qY1nEk8FWtuA7lH+WCOAdHUOtZiLY4JyBYH7YU+c45RJFK+7wfMkT9J2XQYA==)";
        };
      };
    };

    systemd.services.qbittorrent = {
      unitConfig.RequiresMountsFor = ["/media"];
      after = ["proton.service"];
      requires = ["proton.service"];
    };

    # proton hands out a random forwarded port with a 60s lease; keep it
    # renewed, and push it into qbittorrent + the namespace firewall on change
    systemd.services.qbittorrent-natpmp = {
      description = "proton nat-pmp port forwarding for qbittorrent";
      vpnConfinement = {
        enable = true;
        vpnNamespace = "proton";
      };
      after = ["qbittorrent.service"];
      partOf = ["qbittorrent.service"];
      wantedBy = ["qbittorrent.service"];
      path = with pkgs; [libnatpmp curl jq iptables];
      serviceConfig = {
        Restart = "always";
        RestartSec = 10;
      };
      script = ''
        gw=10.2.0.1
        api=http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}/api/v2
        last=""

        iptables -N natpmp 2>/dev/null || true
        iptables -C INPUT -j natpmp 2>/dev/null || iptables -A INPUT -j natpmp

        while true; do
          port=$(natpmpc -a 1 0 tcp 60 -g "$gw" | sed -n 's/^Mapped public port \([0-9]*\).*/\1/p')
          natpmpc -a 1 0 udp 60 -g "$gw" >/dev/null || true

          if [[ -z "$port" ]]; then
            echo "nat-pmp request failed" >&2
            sleep 10
            continue
          fi

          if [[ "$port" != "$last" ]]; then
            echo "forwarded port: $port"
            iptables -F natpmp
            iptables -A natpmp -i proton0 -p tcp --dport "$port" -j ACCEPT
            iptables -A natpmp -i proton0 -p udp --dport "$port" -j ACCEPT
            last=$port
          fi

          cur=$(curl -sf "$api/app/preferences" | jq -r .listen_port) || cur=""
          if [[ "$cur" != "$port" ]]; then
            curl -sf -X POST "$api/app/setPreferences" \
              --data-urlencode "json={\"listen_port\":$port}" \
              && echo "qbittorrent listen port: $cur -> $port"
          fi

          sleep 45
        done
      '';
    };
  };
}
