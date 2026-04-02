{
  pkgs,
  lib,
  config,
  ...
}: {
  options.bootloader.grub.enable = lib.mkEnableOption "enable grub";

  config.boot = lib.mkIf config.bootloader.grub.enable {
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
