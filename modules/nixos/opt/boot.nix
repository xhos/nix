{
  lib,
  config,
  ...
}: {
  options.boot.enable = lib.mkEnableOption "systemd-boot";

  config = lib.mkIf config.boot.enable {
    boot = {
      plymouth.enable = true;
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 5;
          consoleMode = "auto";
        };
        efi.canTouchEfiVariables = true;
      };
    };
  };
}
