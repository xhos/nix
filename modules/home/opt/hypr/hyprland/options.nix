{
  config,
  lib,
  ...
}: {
  wayland.windowManager.hyprland.settings = lib.mkIf (config.de == "hyprland") {
    exec-once = [
      "uwsm-app -- clipse -listen"
      "uwsm-app -- wl-paste --type text --watch cliphist store"
      "uwsm-app -- wl-paste --type image --watch cliphist store"
      "uwsm-app -- gnome-keyring-daemon --start --daemonize"
    ];

    general = {
      gaps_in = 5;
      gaps_out = 10;
      border_size = 1;
      "col.active_border" = "rgba(262626aa)";
      "col.inactive_border" = "rgba(111111aa)";
      layout = "dwindle";

      snap = {
        enabled = true;
        window_gap = 10;
        monitor_gap = 10;
        border_overlap = true;
      };
    };

    "plugin:dynamic-cursors" = {
      enabled = true;
      mode = "stretch";
      threshold = 2;
      shake.enabled = false;
      stretch = {
        limit = 3000;
        function = "quadratic";
      };
    };

    decoration = {
      rounding = 15;
      inactive_opacity = 1;

      shadow = {
        enabled = true;
        range = 20;
        render_power = 4;
        color = "rgba(000000b3)";
        ignore_window = true;
      };

      blur = {
        size = 12;
        passes = 4;
        special = true;
        popups = true;
        noise = 0.0117;
        contrast = 1;
        brightness = 0.4172;
        vibrancy = 0.1696;
      };
    };

    animations = {
      enabled = true;
      bezier = "quart, 0.25, 1, 0.5, 1";

      animation = [
        "windows, 1, 2, quart, slide"
        "border, 1, 2, quart"
        "borderangle, 1, 2, quart"
        "fade, 1, 2, quart"
        "workspaces, 1, 2, quart, slidevert"
      ];
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    device = [
      {
        name = "znt0001:00-14e5:650e-touchpad";
        sensitivity = "+0.2";
      }
      {
        name = "razer-razer-mamba-elite-1";
        accel_profile = "flat";
        sensitivity = "-0.3";
      }
      {
        name = "logitech-g305-1";
        accel_profile = "flat";
        sensitivity = "-0.7";
      }
      {
        name = "dualsense-wireless-controller-touchpad";
        enabled = false;
      }
    ];

    # "plugin:touch_gestures" = {
    #   sensitivity = 5.0;
    #   workspace_swipe_edge = "";
    #   hyprgrass-bindm = ", longpress:2, movewindow";
    #   hyprgrass-bind = ", edge:d:u, exec, toggle-osk";
    # };
    #
    input = {
      kb_layout = "us, ru";
      kb_options = "caps:escape,grp:alt_shift_toggle";

      accel_profile = "adaptive";
      follow_mouse = 1;

      touchpad = {
        disable_while_typing = true;
        natural_scroll = true;
        scroll_factor = 0.5;
      };
    };

    misc = {
      enable_swallow = true; # hide windows that spawn other windows
      swallow_regex = config.terminal; # windows for which swallow is applied
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      focus_on_activate = true; # whether Hyprland should focus an app that requests to be focused (an activate request)
      force_default_wallpaper = 0;
      key_press_enables_dpms = true;
      mouse_move_enables_dpms = true; # if DPMS is set to off, wake up the monitors if the mouse moves
      vfr = true; # lower the amount of sent frames when nothing is happening on-screen
    };

    ecosystem.no_update_news = true;
    cursor.no_hardware_cursors = true;
    xwayland.force_zero_scaling = true;
  };
}
