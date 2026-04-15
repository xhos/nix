{
  lib,
  config,
  osConfig,
  ...
}: {
  options = with lib; {
    profile = mkOption {
      type = types.enum ["minimal" "full" "desktop"];
      default = osConfig.profile or "desktop";
      description = "package tier: minimal = debug/admin essentials, full = + dev CLI, desktop = + GUI";
    };

    headless = lib.mkOption {
      type = lib.types.bool;
      default = config.profile != "desktop";
      defaultText = "profile != \"desktop\"";
      description = "disable all gui related stuff";
    };

    mainMonitor = mkOption {
      type = types.str;
      description = "main monitor of the system, used for hyprlock";
      default = "";
    };

    hyprland = {
      hyprspace.enable = mkEnableOption "enable hyprland overview plugin";
    };

    wm = mkOption {
      type = types.enum [
        "hyprland"
        "niri"
        "none"
      ];
      default = "none";
    };
    bar = mkOption {
      type = types.enum [
        "waybar"
        "none"
      ];
      default = "none";
    };
    browser = mkOption {
      type = types.enum [
        "firefox"
        "zen"
        "none"
      ];
      default = "none";
    };
    terminal = mkOption {
      type = types.enum [
        "wezterm"
        "foot"
        "ghostty"
        "none"
      ];
      default = osConfig.terminal;
    };
    prompt = mkOption {
      type = types.enum [
        "starship"
        "oh-my-posh"
        "none"
      ];
      default = "starship";
    };
    shell = mkOption {
      type = types.enum [
        "zsh"
        "fish"
        "nu"
      ];
      default = "zsh";
    };
  };
}
