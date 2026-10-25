{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "casper";
  networking.hostId = "47725faa";
  services.k3s.serverAddr = "https://10.0.0.15:6443";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./casper.pub];
}
