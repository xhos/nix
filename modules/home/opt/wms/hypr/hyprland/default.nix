{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}: let
  luaDir = ./hypr;

  hostLua = luaDir + "/hosts/${osConfig.networking.hostName}.lua";
  hasHostConfig = builtins.pathExists hostLua;

  colors = config.lib.stylix.colors;

  nixVals = {
    hostname = osConfig.networking.hostName;
    has_host_config = hasHostConfig;

    rounding = config.hyprland.rounding;
    blur = {inherit (config.hyprland.blur) size passes;};
    main_monitor = config.mainMonitor;
    exec_once = config.hyprland.execOnce;

    browser =
      {
        zen = "zen-beta";
        firefox = "firefox";
        none = "";
      }
      .${
        config.browser
      };

    terminal = {
      bin = config.terminal;
      class = config.terminal;
      class_prefix =
        {
          ghostty = "com.mitchellh.ghostty";
          foot = "foot";
          wezterm = "org.wezfurlong.wezterm";
          none = "";
        }
        .${
          config.terminal
        };
      launch =
        if config.terminal == "ghostty"
        then "ghostty --gtk-single-instance=true"
        else config.terminal;
    };

    features = {
      waybar = config.bar == "waybar";
    };

    colors = {
      base00 = "#${colors.base00}";
      base05 = "#${colors.base05}";
      base0D = "#${colors.base0D}";
      accent = "#${colors.base0D}";
    };
  };
in {
  config = lib.mkIf (config.wm == "hyprland") {
    wayland.windowManager.hyprland = {
      enable = true;

      package = osConfig.programs.hyprland.package;
      systemd.enable = false;
      xwayland.enable = true;

      configType = "lua";

      settings = {}; # just to make sure nothing writes to it
      extraConfig = builtins.readFile (luaDir + "/hyprland.lua");

      extraLuaFiles =
        {
          "nix" = {
            content = ''
              return ${lib.generators.toLua {} nixVals}
            '';
            autoLoad = true;
          };

          "binds" = {
            content = luaDir + "/binds.lua";
            autoLoad = false;
          };
          "rules" = {
            content = luaDir + "/rules.lua";
            autoLoad = false;
          };
        }
        // lib.optionalAttrs hasHostConfig {
          "host" = {
            content = hostLua;
            autoLoad = false;
          };
        };
    };

    services.hyprpaper.enable = true;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config.common.default = "*";
      configPackages = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = ["graphical-session-pre.target"];
      };
    };
  };
}
