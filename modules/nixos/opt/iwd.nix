{
  config,
  lib,
  pkgs,
  ...
}: let
  # iwd's TLS layer (ell) only accepts pure PEM. NixOS ships the labelled
  # trust-bundle format instead — a plaintext certificate name on the line
  # before each -----BEGIN CERTIFICATE----- — and ell rejects the whole file
  # with "Failed to load", which breaks every 802.1X (PEAP/TTLS/TLS) network.
  # Both bundles nss-cacert provides have the labels, so strip them once here.
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
