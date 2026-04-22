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

  profile = "desktop";

  networking.hostName = "zireael";
  networking.hostId = "5ca416d5";

  users.users.xhos.openssh.authorizedKeys.keyFiles = [./zireael.pub];

  impermanence.enable = true;
  bluetooth   .enable = true;
  audio       .enable = true;
  syncthing   .enable = true;
  intel       .enable = true;
  games       .enable = true;
  davinci     .enable = true;
  reality-vpn-client.enable = true;

  wm = "hyprland";
  greeter = "yawn";
  bootloader.systemd-boot.enable = true;
  terminal = "ghostty";

  # fix spam on boot
  boot.blacklistedKernelModules = ["acpi_fan"];

  systemd.tmpfiles.rules = [
    "z /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value 0660 xhos users -"
  ];

  hardware.sensor.iio.enable = true; # screen rotation sensor

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fprintd.enable = true;

  # Keep fprintd out of hyprlock's PAM stack — hyprlock talks to fprintd
  # directly over D-Bus (auth.fingerprint), so PAM only handles the password.
  # Without this, pam_fprintd blocks the password path on the lockscreen.
  security.pam.services.hyprlock.fprintAuth = false;

  # LUKS auto decryption via TPM

  # after install:
  # systemd-cryptenroll \
  # --tpm2-device=auto \
  # --tpm2-pcrs=11 \
  # --tpm2-with-pin=yes \
  # /dev/nvme0n1p5

  boot.initrd.systemd.enable = true;
  security.tpm2.enable = true;

  # comment out below 2 lines before install then update the offset with
  # sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  boot.resumeDevice = "/dev/mapper/crypted";
  boot.kernelParams = ["resume_offset=34700103"];

  services.logind = lib.mkForce {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchDocked = "ignore";
    powerKey = "hibernate";
  };

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30min";
    SuspendState = "mem";
  };

  system.stateVersion = "25.05";
}
