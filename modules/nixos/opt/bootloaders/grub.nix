{
  pkgs,
  lib,
  config,
  ...
}: {
  boot = lib.mkIf (config.bootloader == "grub") {
    plymouth.enable = true;
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        backgroundColor = "#000";
        theme = pkgs.minimal-grub-theme;
        useOSProber = true;
        efiSupport = true;
      };
    };
  };
}
