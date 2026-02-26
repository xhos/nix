{
  config,
  lib,
  pkgs,
  ...
}: let
  iconDir = "/home/xhos/nix/modules/home/opt/wms/hypr/hyprland/icons";

  brightness-script = pkgs.writeShellScriptBin "brightness-script" ''
    #!/bin/bash
    iDIR="${iconDir}"
    notification_timeout=1000

    get_backlight() {
      echo $(brightnessctl -m | cut -d, -f4)
    }

    get_icon() {
      current=$(get_backlight | sed 's/%//')
      if   [ "$current" -le "20" ]; then
        icon="$iDIR/brightness-20.png"
      elif [ "$current" -le "40" ]; then
        icon="$iDIR/brightness-40.png"
      elif [ "$current" -le "60" ]; then
        icon="$iDIR/brightness-60.png"
      elif [ "$current" -le "80" ]; then
        icon="$iDIR/brightness-80.png"
      else
        icon="$iDIR/brightness-100.png"
      fi
    }

    notify_user() {
      notify-send -e -h string:x-canonical-private-synchronous:brightness_notif -h int:value:$current -u low -i "$icon" "Brightness : $current%"
    }

    change_backlight() {
      brightnessctl set "$1" && get_icon && notify_user
    }

    case "$1" in
      "--get")
        get_backlight
        ;;
      "--inc")
        change_backlight "+10%"
        ;;
      "--dec")
        change_backlight "10%-"
        ;;
      *)
        get_backlight
        ;;
    esac
  '';

  volume-script = pkgs.writeShellScriptBin "volume-script" ''
    #!/usr/bin/env bash
    iDIR="${iconDir}"

    get_volume() {
        volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
        volume=$(echo "$volume_info" | awk '{print int($2 * 100)}')

        if echo "$volume_info" | grep -q "MUTED"; then
            echo "Muted"
        else
            echo "$volume%"
        fi
    }

    get_icon() {
        current=$(get_volume)
        if [[ "$current" == "Muted" ]]; then
            echo "$iDIR/volume-mute.png"
        elif [[ "''${current%\%}" -le 30 ]]; then
            echo "$iDIR/volume-down.png"
        elif [[ "''${current%\%}" -le 60 ]]; then
            echo "$iDIR/volume-mid.png"
        else
            echo "$iDIR/volume-up.png"
        fi
    }

    notify_user() {
        if [[ "$(get_volume)" == "Muted" ]]; then
            notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: Muted"
        else
            notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" "Volume: $(get_volume)"
        fi
    }

    inc_volume() {
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify_user
    }

    dec_volume() {
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify_user
    }

    toggle_mute() {
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify_user
    }

    toggle_mic() {
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        mic_status=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
        if echo "$mic_status" | grep -q "MUTED"; then
            notify-send -e -u low -i "$iDIR/microphone-mute.png" "mic off"
        else
            notify-send -e -u low -i "$iDIR/microphone.png" "mic on"
        fi
    }

    get_mic_icon() {
        mic_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
        if echo "$mic_info" | grep -q "MUTED"; then
            echo "$iDIR/microphone-mute.png"
        else
            echo "$iDIR/microphone.png"
        fi
    }

    get_mic_volume() {
        mic_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
        volume=$(echo "$mic_info" | awk '{print int($2 * 100)}')

        if echo "$mic_info" | grep -q "MUTED"; then
            echo "Muted"
        else
            echo "$volume%"
        fi
    }

    notify_mic_user() {
        volume=$(get_mic_volume)
        icon=$(get_mic_icon)
        if [[ "$volume" == "Muted" ]]; then
            notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$icon" "Mic-Level: Muted"
        else
            notify-send -e -h int:value:"''${volume%\%}" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$icon" "Mic-Level: $volume"
        fi
    }

    inc_mic_volume() {
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%+ && notify_mic_user
    }

    dec_mic_volume() {
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- && notify_mic_user
    }

    if [[ "$1" == "--get" ]]; then
      get_volume
    elif [[ "$1" == "--inc" ]]; then
      inc_volume
    elif [[ "$1" == "--dec" ]]; then
      dec_volume
    elif [[ "$1" == "--toggle" ]]; then
      toggle_mute
    elif [[ "$1" == "--toggle-mic" ]]; then
      toggle_mic
    elif [[ "$1" == "--get-icon" ]]; then
      get_icon
    elif [[ "$1" == "--get-mic-icon" ]]; then
      get_mic_icon
    elif [[ "$1" == "--mic-inc" ]]; then
      inc_mic_volume
    elif [[ "$1" == "--mic-dec" ]]; then
      dec_mic_volume
    else
      get_volume
    fi
  '';
in {
  config = lib.mkIf (config.wm == "hyprland") {
    home.packages = with pkgs; [
      # things actully neeeded on hyprland
      # ----
      brightness-script
      volume-script
      # TUI control tools
      wiremix # audio mixer
      bluetui # bluetooth manager
      impala # network manager

      bemoji # emoji picker
      clipse # clipboard manager
      swww

      wvkbd

      # TODO: this.
      autotiling-rs
      brightnessctl
      cliphist
      dbus
      glib
      grim
      gtk3
      hyprpicker
      libcanberra-gtk3
      pamixer
      sassc
      slurp
      wf-recorder
      wl-clipboard
      wl-screenrec
      wlr-randr
      wlr-randr
      wtype
      ydotool
      wlprop
      xorg.xprop
    ];
  };
}
