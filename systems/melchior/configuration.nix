{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "melchior";
  networking.hostId = "663898f4";
  services.k3s.serverAddr = "https://10.0.0.16:6443";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./melchior.pub];
}
