{
  config,
  lib,
  pkgs,
  ...
}: let
  # iwd's TLS lib rejects nixos's labelled cert bundle, breaks 802.1X. strip to pure PEM.
  caBundlePem = pkgs.runCommand "iwd-ca-certificates.pem" {} ''
    sed -n "/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p" \
      ${config.security.pki.caBundle} > $out
    grep -q "BEGIN CERTIFICATE" $out
  '';
in {
  config = lib.mkIf (!config.headless) {
    networking.wireless.iwd = {
      enable = true;

      settings = {
        General = {
          EnableNetworkConfiguration = true;
          AddressRandomization = "network";
        };
      };
    };

    networking.dhcpcd.enable = false;
    networking.useDHCP = false;

    systemd.network = {
      enable = true;

      networks."10-wired" = {
        matchConfig = {
          Type = "ether";
          Kind = "!*";
        };
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        linkConfig.RequiredForOnline = "no";
      };

      wait-online.enable = false;
    };

    # Referenced from 802.1X network files as
    #   EAP-PEAP-CACert=/etc/iwd/ca-certificates.pem
    environment.etc."iwd/ca-certificates.pem".source = caBundlePem;

    persist.dirs = ["/var/lib/iwd"];
  };
}
