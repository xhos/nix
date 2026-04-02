{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "zireael";
  networking.hostId = "5ca416d5";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./zireael.pub];

  impermanence.enable = true;
  bluetooth   .enable = true;
  audio       .enable = true;
  syncthing   .enable = true;
  vm          .enable = true;

  wm = "hyprland";
  greeter = "yawn";
  bootloader.systemd-boot.enable = true;
  terminal = "ghostty";

  systemd.tmpfiles.rules = [
    "z /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value 0660 xhos users -"
  ];

  hardware.sensor.iio.enable = true; # screen rotation sensor

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fprintd.enable = true;

  # LUKS auto decryption via TPM

  # after install:
  # systemd-cryptenroll \
  # --tpm2-device=auto \
  # --tpm2-pcrs=11 \
  # --tpm2-with-pin=yes \
  # /dev/nvme0n1p5

  boot.initrd.systemd.enable = true;
  security.tpm2.enable = true;

  # hibernation setup
  boot.resumeDevice = "/dev/mapper/crypted";
  boot.kernelParams = ["resume_offset=8716550"];
  services.logind = lib.mkForce {
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
    powerKey = "hibernate";
  };

  system.stateVersion = "25.05";
}
