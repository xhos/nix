{inputs, ...}: {
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  headless = true;

  networking.hostName = "null";
  # head -c 8 /etc/machine-id
  # or
  # openssl rand -hex 4
  networking.hostId = "d75676d6";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./null.pub];

  bootloader.systemd-boot.enable = true;
}
