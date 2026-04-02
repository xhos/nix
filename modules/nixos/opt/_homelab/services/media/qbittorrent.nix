{config, ...}: {
  # create the downloads dir
  systemd.tmpfiles.rules = ["d /storage/media/downloads 0775 root media -"];

  # all torrent traffic goes through proton vpn
  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "proton";
  };

  _enrai.exposedServices.qbittorrent = {
    port = config.services.qbittorrent.webuiPort;
    upstream = config.vpnNamespaces.proton.namespaceAddress;
  };

  services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "media";

    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent.Session.DefaultSavePath = "/storage/media/downloads";
      Preferences.WebUI = {
        Address = "0.0.0.0";
        Username = "admin";
        # https://gist.github.com/hastinbe/8b8d247f17481cfc262a98d661bc0fd5
        Password_PBKDF2 = "@ByteArray(cWgbdiY0hx3ipPWL3nGZBg==:RlTSPXDqYIbTTw0Hr2EzSh56H/qY1nEk8FWtuA7lH+WCOAdHUOtZiLY4JyBYH7YU+c45RJFK+7wfMkT9J2XQYA==)";
      };
    };
  };

  systemd.services.qbittorrent = {
    after = ["proton.service"];
    requires = ["proton.service"];
  };
}
