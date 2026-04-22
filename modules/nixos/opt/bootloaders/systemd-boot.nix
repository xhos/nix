{
  lib,
  config,
  pkgs,
  ...
}: {
  options.bootloader.systemd-boot.enable = lib.mkEnableOption "enable systemd-boot";

  config.boot = lib.mkIf config.bootloader.systemd-boot.enable {
    kernelParams = ["quiet" "splash" "rd.udev.log_level=3" "udev.log_priority=3"];
    consoleLogLevel = 0;
    initrd.verbose = false;

    plymouth = {
      enable = true;
      theme = "hexagon";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = ["hexagon"];
        })
      ];
    };
    loader = {
      timeout = 0; # skip the bootloader unless i hold down a key
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
        rebootForBitlocker = true;
      };
    };
  };
}
