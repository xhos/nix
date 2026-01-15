{
  lib,
  config,
  ...
}: let
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

    firewall = {
      enable = true;
      allowedTCPPorts = [sshPort];
    };
  };
}
