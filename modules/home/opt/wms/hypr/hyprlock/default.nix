{
  config,
  pkgs,
  lib,
  ...
}: let
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
            size = 320
            rounding = -1
            rotate = 0
            reload_time = -1
            reload_cmd =
            position = 250, 120
            halign = left
            valign = center
        }

        # username
        label {
            monitor = $monitor
            text =  $USER
            color = $foreground
            outline_thickness = 0
            font_size = 22
            font_family = $regular_font
            position = 350, -80
            halign = left
            valign = center
        }

        # password
        input-field {
            monitor = $monitor
            size = 320, 60
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
            position = 250, -150
            halign = left
            valign = center
        }

        ------------------- DATE TIME -------------------
        # time
        label {
            monitor = $monitor
            text = cmd[update:1000] echo "$(date +"%H:%M")"
            color = $accent
            font_size = 300
            rotate = -90
            font_family = $mono_font
            position = 115, 38
            halign = right
            valign = top
        }

        # date/month
        label {
            monitor = $monitor
            text = cmd[update:1000] echo "$(date +"%d/%m")"
            color = $accent
            font_size = 300
            font_family = $mono_font
            position = 40, -75
            halign = right
            valign = bottom
        }


        --------------------- MISC ----------------------
        # current song
        label {
            monitor = $monitor
            text = cmd[update:1000] echo "$(sh $song_script)"
            color = $foreground
            font_size = 25
            text_align = center
            font_family = $alt_font
            position = 10, 5
            halign = left
            valign = bottom
        }
      '';
    };
  }
