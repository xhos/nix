{lib, ...}: {
  options = with lib; {
    headless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "disable all gui related stuff";
    };

    greeter = mkOption {
      type = types.enum ["autologin" "sddm" "yawn" "none"];
      default = "none";
      description = "which greeter to use";
    };

    wm = mkOption {
      type = types.enum ["hyprland" "niri" "none"];
      default = "none";
      description = "which wm to use";
    };

    terminal = mkOption {
      type = types.enum ["wezterm" "foot" "ghostty" "none"];
      default = "none";
      description = "default terminal emulator";
    };
  };
}
