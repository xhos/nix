{
  config,
  lib,
  ...
}: {
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

    persist.dirs = ["/var/lib/iwd"];
  };
}
