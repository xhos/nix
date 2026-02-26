{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.bar == "waybar") {
    programs.waybar.style = with config.lib.stylix.colors; ''
      @define-color background #000000;
      @define-color foreground #${base07};
      @define-color text #${base05};
      @define-color color0 #${base00};
      @define-color color1 #${base01};
      @define-color color2 #${base02};
      @define-color color3 #${base03};
      @define-color color4 #${base04};
      @define-color color5 #${base05};
      @define-color color6 #${base06};
      @define-color color7 #${base07};
      @define-color color8 #${base0D};
      @define-color color9 #${base05};
      @define-color color10 #${base0C};
      @define-color color11 #${base0B};
      @define-color color12 #${base0C};
      @define-color color13 #${base0C};
      @define-color color14 #${base0E};
      @define-color color15 #${base08};
      @define-color active #${base0C};
      @define-color inactive #${base03};

      * {
        font-family: "Monospec";
        font-size: 11px;
        border: none;
        min-height: 0;
        min-width: 0;
      }

      window#waybar {
        background: rgba(0, 0, 0, 1);
        color: @text;
      }

      #clock,
      #network,
      #pulseaudio,
      #pulseaudio.microphone,
      #battery,
      #language,
      #custom-recording,
      #custom-whisper,
      #custom-camera-cover {
        padding: 4px 0;
        margin: 1px 0;
        color: @text;
      }

      #clock {
        font-size: 16px;
        color: @foreground;
      }

      #workspaces {
        margin: 0;
        padding: 0;
      }

      #workspaces button {
        color: @inactive;
        padding: 3px 0;
        background: transparent;
        border-radius: 0;
      }

      #workspaces button.empty {
        color: @inactive;
      }

      #workspaces button.active,
      #workspaces button.focused {
        color: @color7;
      }

      #network.disabled,
      #network.disconnected {
        color: @inactive;
      }

      #pulseaudio.sink-muted:not(.microphone) {
        color: @inactive;
      }

      #pulseaudio.microphone.source-muted {
        color: @inactive;
      }

      #battery.plugged,
      #battery.full,
      #battery.charging {
        color: @color11;
      }

      #battery.warning {
        color: #${base0A};
      }

      #battery.critical {
        color: #${base08};
      }

      #custom-recording.recording-active,
      #custom-whisper.recording-active {
        color: #${base08};
      }

      #custom-whisper.transcribing-active {
        color: #${base0A};
      }

      tooltip {
        background: @background;
        color: @text;
        border: 1px solid @color2;
      }
    '';
  };
}
