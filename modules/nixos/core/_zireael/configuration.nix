{inputs, ...}: {
  imports = [
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "zireael";
  networking.hostId = "5ca416d5";

  boot.supportedFilesystems = ["zfs"];

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./zireael.pub];

  impermanence.enable = false;
  bluetooth   .enable = true;
  greetd      .enable = true;
  audio       .enable = true;
  boot        .enable = true;
  syncthing   .enable = true;

  greeter = "yawn";
  systemd.tmpfiles.rules = [
    "z /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value 0660 xhos users -"
  ];
  hardware.sensor.iio.enable = true; # screen rotation sensor
  # boot.kernelPackages = pkgs.linuxPackages_;
  services.fprintd.enable = true;
}
