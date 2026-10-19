{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "melchior";
  networking.hostId = "663898f4";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./melchior.pub];
}
