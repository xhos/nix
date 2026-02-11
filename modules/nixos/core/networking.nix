{
  lib,
  config,
  ...
}: let
  # TODO: this is silly, need to change to 22.
  sshPort = 10022;
in {
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    ports = [sshPort];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      StreamLocalBindUnlink = "yes"; # automatically remove stale sockets
      GatewayPorts = "clientspecified"; # allow forwarding ports to everywhere
    };
  };

  networking = {
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
      allowedTCPPorts = [sshPort];
    };
  };
}
