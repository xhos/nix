{lib, ...}: {
  options.hyprland = with lib; {
    rounding = mkOption {
      type = types.int;
      default = 15;
      description = "Hyprland decoration corner radius";
    };

    blur = {
      size = mkOption {
        type = types.int;
        default = 12;
        description = "Hyprland decoration blur size";
      };

      passes = mkOption {
        type = types.int;
        default = 4;
        description = "Hyprland decoration blur passes";
      };
    };

    execOnce = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
}
