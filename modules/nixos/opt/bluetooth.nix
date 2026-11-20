{
  config,
  lib,
  ...
}: {
  options.bluetooth.enable = lib.mkEnableOption "Bluetooth support";

  config = lib.mkIf config.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          FastConnectable = true;
          JustWorksRepairing = "always";
          Experimental = true; # battery levels over dbus
        };
        Policy.ReconnectAttempts = 7;
      };
    };
  };
}
