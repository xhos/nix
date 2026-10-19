{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "balthasar";
  networking.hostId = "a064d856";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./balthasar.pub];
}
