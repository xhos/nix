{
  lib,
  config,
  ...
}: {
  config = lib.mkIf (config.bar == "waybar") {
    programs.waybar.style = with config.lib.stylix.colors; ''
      @define-color ink #${base00};
      @define-color text #${base05};
      @define-color foreground #${base07};
      @define-color muted mix(#${base03}, @text, 0.38);
      @define-color urgent #${base08};
      @define-color sage #${base0B};
      @define-color amber #${base0A};

      * {
        font-family: "Monospec", "Noto Sans CJK JP", monospace;
        font-size: 11px;
        border: none;
        min-height: 0;
        min-width: 0;
        text-shadow: none;
      }

      /* A nonzero alpha lets Hyprland apply its layer blur. */
      window#waybar {
        background: alpha(@ink, 0.01);
        color: @text;
      }

      .modules-left {
        margin-top: 7px;
      }

      .modules-right {
        margin-bottom: 7px;
      }

      #clock,
      #network,
      #pulseaudio,
      #battery,
      #language,
      #custom-recording,
      #custom-whisper,
      #custom-camera-cover {
        padding: 4px 0;
        margin: 1px 3px;
        border-radius: 0;
        color: @text;
      }

      #clock {
        font-size: 16px;
        font-weight: normal;
        color: @foreground;
        padding: 6px 0;
        margin: 3px;
      }

      #workspaces {
        margin: 0 3px;
        padding: 0;
      }

      #workspaces button {
        color: @muted;
        padding: 4px 0;
        margin: 1px 0;
        background-image: none;
        background-color: transparent;
        box-shadow: none;
        border-radius: 0;
        transition: color 160ms ease;
      }

      #workspaces button.empty {
        color: alpha(@muted, 0.65);
      }

      #workspaces button:hover {
        color: @foreground;
      }

      /* Use the glyph itself to indicate the active workspace. */
      #workspaces button.active,
      #workspaces button.focused {
        color: @foreground;
      }

      #workspaces button.urgent {
        color: @urgent;
      }

      /* Separate workspace groups belonging to different monitors. */
      #workspaces button.hosting-monitor + button:not(.hosting-monitor),
      #workspaces button:not(.hosting-monitor) + button.hosting-monitor {
        margin-top: 6px;
        padding-top: 9px;
        border-top: 1px solid alpha(@text, 0.14);
      }

      #tray {
        margin: 0 3px 6px;
        padding: 6px 0;
      }

      #language {
        color: @muted;
        font-size: 10px;
      }

      #network,
      #pulseaudio {
        transition: color 160ms ease;
      }

      #network:hover,
      #pulseaudio:hover {
        color: @foreground;
      }

      #network.disabled,
      #network.disconnected,
      #pulseaudio.sink-muted:not(.microphone),
      #pulseaudio.microphone.source-muted {
        color: @muted;
      }

      #battery.plugged,
      #battery.full,
      #battery.charging {
        color: @sage;
      }

      #battery.warning,
      #custom-whisper.transcribing-active {
        color: @amber;
      }

      #battery.critical,
      #custom-recording.recording-active,
      #custom-whisper.recording-active,
      #custom-camera-cover.camera-open {
        color: @urgent;
      }

      tooltip {
        background-color: alpha(@ink, 0.96);
        color: @text;
        border: 1px solid alpha(@text, 0.18);
        border-radius: 6px;
      }

      tooltip label {
        padding: 6px 8px;
        color: @text;
      }
    '';
  };
}
