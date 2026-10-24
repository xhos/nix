{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "casper";
  networking.hostId = "47725faa";
  networking.interfaces.lan0.ipv4.addresses = [
    {
      address = "10.0.0.17";
      prefixLength = 24;
    }
  ];

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./casper.pub];
}
