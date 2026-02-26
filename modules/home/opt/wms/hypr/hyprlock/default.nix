{
  config,
  pkgs,
  lib,
  ...
}: let
  # Resolution configuration
  is4K = false; # Set to false for 1920x1080
  scale =
    if is4K
    then 1.0
    else 0.5;
  loginScale =
    if is4K
    then 1.0
    else 0.75; # Larger scale for login section on 1080p

  # Center of blurred section: w/4 / 2 = w/8
  # For 4K (3840): center at 480px, for 1080p (1920): center at 240px
  loginOffsetX =
    if is4K
    then 0
    else 67; # Shift left to center in blurred section on 1080p (240px center - 120px for pfp centering = ~120px target position)

  srcWallpaper = config.stylix.image;
  lockBgPath = "${config.home.homeDirectory}/.config/hypr/hyprlock.png";

  blur = config.wayland.windowManager.hyprland.settings.decoration.blur;

  wp-blur =
    pkgs.writers.writePython3Bin "wp-blur"
    {
      libraries = with pkgs.python3Packages; [
        opencv4
        numpy
      ];
    }
    ''
      import cv2
      import sys
      img = cv2.imread(sys.argv[1])
      h, w = img.shape[:2]
      roi = img[:, :w // 4]
      for _ in range(${toString blur.passes}):
          roi = cv2.GaussianBlur(roi, (0, 0), ${toString blur.size})
      img[:, :w // 4] = roi
      cv2.imwrite(sys.argv[2], img)
    '';
  song-detail = pkgs.writeShellScriptBin "song-detail" ''
    #!/usr/bin/bash
    song_info=$(playerctl metadata --format '󰝚    {{title}} - {{artist}}')
    echo "$song_info" | tr '[:lower:]' '[:upper:]'
  '';
in
  lib.mkIf (config.wm == "hyprland") {
    home.packages = [
      wp-blur
      song-detail
    ];

    home.activation.generateHyprlockBg = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$(dirname ${lockBgPath})"
      ${wp-blur}/bin/wp-blur "${srcWallpaper}" "${lockBgPath}"
    '';

    programs.hyprlock = {
      enable = true;
      extraConfig = with config.lib.stylix.colors; ''
        -------------------- CONFIG ---------------------
        $mono_font = MonoSpec Bold Condensed
        $regular_font = Ndot57
        $alt_font = Synchro
        $foreground = #${base05}
        $accent = #${base0D}
        $wallpaper = ${lockBgPath}
        $pfp = ~/Pictures/pfp.jpg
        $monitor = ${config.mainMonitor}
        $song_script = song-detail

        -------------------- GENERAL --------------------
        general {
          disable_loading_bar     = true,
          hide_cursor             = true,
          ignore_empty_input      = true,
          immediate_render        = true
        }

        background {
          path = $wallpaper
        }

        --------------------- LOGIN ---------------------
        # pfp
        image {
            monitor = $monitor
            path = $pfp
            border_size = 0
            size = ${toString (builtins.floor (320 * loginScale))}
            rounding = -1
            rotate = 0
            reload_time = -1
            reload_cmd =
            position = ${toString (builtins.floor (250 * loginScale - loginOffsetX))}, ${toString (builtins.floor (120 * loginScale))}
            halign = left
            valign = center
        }

        # username
        label {
            monitor = $monitor
            text =  $USER
            color = $foreground
            outline_thickness = 0
            font_size = ${toString (builtins.floor (22 * loginScale))}
            font_family = $regular_font
            position = ${toString (builtins.floor (350 * loginScale - loginOffsetX))}, ${toString (builtins.floor (-80 * loginScale))}
            halign = left
            valign = center
        }

        # password
        input-field {
            monitor = $monitor
            size = ${toString (builtins.floor (320 * loginScale))}, ${toString (builtins.floor (60 * loginScale))}
            outline_thickness = 0
            dots_size = 0.2
            dots_spacing = 0.2
            dots_center = true
            outer_color = rgba(255, 255, 255, 0)
            inner_color = rgba(255, 255, 255, 0.1)
            font_color = $foreground
            fade_on_empty = false
            font_family = $regular_font
            placeholder_text = pswd
            hide_input = false
            position = ${toString (builtins.floor (250 * loginScale - loginOffsetX))}, ${toString (builtins.floor (-150 * loginScale))}
            halign = left
            valign = center
        }

        ------------------- DATE TIME -------------------
        # time
        label {
            monitor = $monitor
            text = cmd[update:1000] echo "$(date +"%H:%M")"
            color = $accent
            font_size = ${toString (builtins.floor (300 * scale))}
            rotate = -90
            font_family = $mono_font
            position = ${toString (builtins.floor (115 * scale))}, ${toString (builtins.floor (38 * scale))}
            halign = right
            valign = top
        }

        # date/month
        label {
            monitor = $monitor
            text = cmd[update:1000] echo "$(date +"%d/%m")"
            color = $accent
            font_size = ${toString (builtins.floor (300 * scale))}
            font_family = $mono_font
            position = ${toString (builtins.floor (40 * scale))}, ${toString (builtins.floor (-75 * scale))}
            halign = right
            valign = bottom
        }


        --------------------- MISC ----------------------
        # current song
        label {
            monitor = $monitor
            text = cmd[update:1000] echo "$(sh $song_script)"
            color = $foreground
            font_size = ${toString (builtins.floor (25 * scale))}
            text_align = center
            font_family = $alt_font
            position = ${toString (builtins.floor (10 * scale))}, ${toString (builtins.floor (5 * scale))}
            halign = left
            valign = bottom
        }
      '';
    };
  }
