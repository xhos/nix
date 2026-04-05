{
  lib,
  config,
  ...
}: {
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      StreamLocalBindUnlink = "yes"; # automatically remove stale sockets
      GatewayPorts = "clientspecified"; # allow forwarding ports to everywhere
    };
  };

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1"];
    networkmanager.enable = lib.mkIf (config.headless != true) true;

    firewall = rec {
      enable = true;
      allowedTCPPortRanges = [
        {
          # kdeconnect
          # TODO: this should be conditional
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
      allowedTCPPorts = [22];
    };
  };
}
