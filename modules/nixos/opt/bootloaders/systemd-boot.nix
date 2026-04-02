{
  lib,
  config,
  ...
}: {
  options.bootloader.systemd-boot.enable = lib.mkEnableOption "enable systemd-boot";

  config.boot = lib.mkIf config.bootloader.systemd-boot.enable {
    plymouth.enable = true;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "auto";
        rebootForBitlocker = true;
      };
    };
  };
}
