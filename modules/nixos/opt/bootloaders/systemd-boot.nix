{
  lib,
  config,
  ...
}: {
  boot = lib.mkIf (config.bootloader == "systemd-boot") {
    plymouth.enable = true;
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "auto";
        rebootForBitlocker = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
