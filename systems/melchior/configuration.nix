{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "melchior";
  networking.hostId = "663898f4";
  networking.interfaces.lan0.ipv4.addresses = [
    {
      address = "10.0.0.15";
      prefixLength = 24;
    }
  ];

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./melchior.pub];
}
