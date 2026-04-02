{config, ...}: {
  sops.secrets."vpn/proton" = {};

  vpnNamespaces.proton = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."vpn/proton".path;
    accessibleFrom = [
      "10.0.0.0/24"
      # "10.100.0.0/24"
    ];

    portMappings = [
      {
        # qBittorrent web UI port
        from = 8080;
        to = 8080;
      }
    ];

    openVPNPorts = [
      {
        # default torrent port
        port = 6881;
        protocol = "both";
      }
    ];
  };
}
