{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.bar == "waybar") {
    programs.waybar.settings.main = let
      whisper-status-script = pkgs.writeShellApplication {
        name = "whisper-status";
        runtimeInputs = with pkgs; [coreutils];
        text = ''
          DIR="/tmp/whisper-dictate"
          REC_PID="$DIR/recording.pid"
          TRN_FLAG="$DIR/transcribing.flag"

          if [[ -f "$TRN_FLAG" ]]; then
            echo '{"text":"💾 TXT","tooltip":"Transcribing…","class":"transcribing-active"}'
            exit 0
          fi

          if [[ -f "$REC_PID" ]] && kill -0 "$(cat "$REC_PID")" 2>/dev/null; then
            echo '{"text":"🎙️ REC","tooltip":"Recording…","class":"recording-active"}'
            exit 0
          fi

          echo '{}'
        '';
      };

      recording-status-script = pkgs.writeShellApplication {
        name = "recording-status";
        runtimeInputs = with pkgs; [procps];
        text = ''
          if pgrep -x "wf-recorder" > /dev/null; then
            echo '{"text": "🔴 REC", "tooltip": "Recording active", "class": "recording-active"}'
          else
            echo '{"text": "", "tooltip": "", "class": "recording-inactive"}'
          fi
        '';
      };

      recorder-script = pkgs.writeShellApplication {
        name = "recorder";
        runtimeInputs = with pkgs; [wf-recorder rofi libnotify hyprland procps gawk coreutils];
        text = ''
          DIRECTORY="$HOME/screenrecord"

          if [ ! -d "$DIRECTORY" ]; then
              mkdir -p "$DIRECTORY"
          fi

          if pgrep -x "wf-recorder" > /dev/null; then
              pkill -INT -x wf-recorder
              notify-send -h string:wf-recorder:record -t 2500 "Finished Recording" "Saved at $DIRECTORY"
              ${recording-status-script}/bin/recording-status
              exit 0
          fi

          MONITORS=$(hyprctl monitors | grep "^Monitor " | awk '{print $2}')
          SELECTED_MONITOR=$(echo "$MONITORS" | rofi -dmenu -p "Record Monitor:")

          if [ -n "$SELECTED_MONITOR" ]; then
              dateTime=$(date +%a-%b-%d-%y-%H-%M-%S)
              notify-send -h string:wf-recorder:record -t 1500 "Recording Monitor" "Starting recording on: $SELECTED_MONITOR"
              wf-recorder -o "$SELECTED_MONITOR" -f "$DIRECTORY/$dateTime.mp4" &
          elif [ -z "$SELECTED_MONITOR" ]; then
              exit 0
          else
              notify-send "Error" "No monitor selected."
              exit 1
          fi
        '';
      };

      camera-cover-script = pkgs.writeShellApplication {
        name = "camera-cover-status";
        runtimeInputs = with pkgs; [coreutils];
        text = ''
          ATTR_FILE="/sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value"
          CACHE_FILE="/tmp/.camera_cover_unavailable"

          if [ -f "$CACHE_FILE" ]; then
              echo '{}'
              exit 0
          fi

          if [ ! -f "$ATTR_FILE" ]; then
              touch "$CACHE_FILE"
              echo '{}'
              exit 0
          fi

          value=$(cat "$ATTR_FILE" 2>/dev/null)

          if [ "$value" = "0" ]; then
              echo '{"text": "🔴", "tooltip": "Camera cover open", "class": "camera-open"}'
          else
              echo '{"text": "", "tooltip": "Camera cover closed", "class": "camera-closed"}'
          fi
        '';
      };
    in {
      output = config.mainMonitor;
      position = "left";
      layer = "overlay";
      width = 34;

      "modules-left" = [
        "hyprland/workspaces"
        "niri/workspaces"
      ];

      "modules-center" = [
        "clock"
        "custom/recording"
        "custom/whisper"
        "custom/camera-cover"
      ];

      "modules-right" = [
        "tray"
        "hyprland/language"
        "niri/language"
        "network"
        "pulseaudio#microphone"
        "pulseaudio"
        "battery"
      ];

      "hyprland/workspaces" = {
        "format" = "{icon}";
        "format-icons" = {
          "1" = "一";
          "2" = "二";
          "3" = "三";
          "4" = "四";
          "5" = "五";
          "6" = "六";
          "7" = "七";
          "8" = "八";
          "9" = "九";
          "10" = "十";
          "11" = "一";
          "12" = "二";
          "13" = "三";
          "14" = "四";
          "15" = "五";
          "16" = "六";
          "17" = "七";
          "18" = "八";
          "19" = "九";
          "20" = "十";
        };
      };

      "niri/workspaces" = {
        "format" = "{icon}";
        "format-icons" = {
          "1" = "一";
          "2" = "二";
          "3" = "三";
          "4" = "四";
          "5" = "五";
          "6" = "六";
          "7" = "七";
          "8" = "八";
          "9" = "九";
          "10" = "十";
        };
      };

      "clock" = {
        "format" = "{0:%H}\n{0:%M}";
        "format-alt" = "{0:%a}\n{0:%d}";
        "interval" = 1;
        "tooltip-format" = "<tt>{calendar}</tt>";
      };

      "hyprland/language" = {
        "format-en" = "en";
        "format-ru" = "ru";
      };

      "niri/language" = {
        "format" = "{short}";
      };

      "network" = {
        "format-disabled" = "---";
        "format-disconnected" = "dsc";
        "format-ethernet" = "eth";
        "format-wifi" = "wif";
        "tooltip-format" = "{essid}\n{ipaddr}\n{ifname}";
      };

      "pulseaudio" = {
        "format" = "v{volume}";
        "format-muted" = "vmx";
        "on-click" = "volume-script --toggle";
        "reverse-scrolling" = true;
        "tooltip" = true;
        "tooltip-format" = "vol: {volume}%\n{desc}";
      };

      "pulseaudio#microphone" = {
        "format" = "m{format_source}";
        "format-source" = "{volume}";
        "format-source-muted" = "mx";
        "on-click" = "volume-script --toggle-mic";
        "tooltip" = true;
        "tooltip-format" = "mic: {volume}%";
      };

      "battery" = {
        "interval" = 5;
        "states" = {
          "full" = 100;
          "notfull" = 99;
          "warning" = 20;
          "critical" = 10;
        };
        "format-charging" = "c{capacity}";
        "format-critical" = "!{capacity}";
        "format-full" = "f{capacity}";
        "format-notfull" = "{capacity}%";
        "format-plugged" = "p{capacity}";
        "format-warning" = "~{capacity}";
        "tooltip" = true;
        "tooltip-format" = "bat: {capacity}%\n{timeTo}";
      };

      "custom/recording" = {
        "exec" = "${recording-status-script}/bin/recording-status";
        "interval" = 1;
        "on-click" = "${recorder-script}/bin/recorder";
        "return-type" = "json";
      };

      "custom/whisper" = {
        "exec" = "${whisper-status-script}/bin/whisper-status";
        "interval" = 1;
        "on-click" = "whspr";
        "return-type" = "json";
      };

      "custom/camera-cover" = {
        "exec" = "${camera-cover-script}/bin/camera-cover-status";
        "interval" = 1;
        "return-type" = "json";
      };
    };
  };
}
