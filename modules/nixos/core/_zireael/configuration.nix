{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "zireael";
  networking.hostId = "5ca416d5";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./zireael.pub];

  impermanence.enable = false;
  bluetooth   .enable = true;
  audio       .enable = true;
  boot        .enable = true;
  syncthing   .enable = true;
  vm          .enable = true;

  greeter = "yawn";
  terminal = "ghostty";
  wm = "niri";

  systemd.tmpfiles.rules = [
    "z /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value 0660 xhos users -"
  ];
  hardware.sensor.iio.enable = true; # screen rotation sensor

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fprintd.enable = true;
}
