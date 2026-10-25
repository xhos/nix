{
  imports = [
    ../magi/common.nix
    ./hardware-configuration.nix
  ];

  impermanence.enable = true;

  networking.hostName = "balthasar";
  networking.hostId = "a064d856";
  services.k3s.serverAddr = "https://10.0.0.15:6443";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./balthasar.pub];
}
