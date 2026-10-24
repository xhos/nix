{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "balthasar";
  networking.hostId = "a064d856";
  networking.interfaces.lan0.ipv4.addresses = [
    {
      address = "10.0.0.16";
      prefixLength = 24;
    }
  ];

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./balthasar.pub];
}
