{
  pkgs,
  lib,
  config,
  ...
}: {
  options.boot.enable = lib.mkEnableOption "GRUB bootloader with Plymouth";

  config = lib.mkIf config.boot.enable {
    boot = {
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
  };
}
