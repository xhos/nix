{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "casper";
  networking.hostId = "47725faa";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./casper.pub];
}
