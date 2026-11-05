{
  flake.modules.nixos.clips = {
    # setcap wrapper for gsr-kms-server, which reads the screen without going through the compositor
    programs.gpu-screen-recorder.enable = true;
  };

  flake.modules.homeManager.clips = {
    config,
    lib,
    pkgs,
    ...
  }: let
    service = "gpu-screen-recorder-replay";
    clipDir = "${config.home.homeDirectory}/Videos/clips";

    # ffmpeg 9 needs nvenc api 13.1, the 595 driver only has 13.0
    gpu-screen-recorder = pkgs.gpu-screen-recorder.override {ffmpeg = pkgs.ffmpeg_8;};

    # runs after the file is written, so this can't report a clip that doesn't exist
    saved = pkgs.writeShellScript "clip-saved" ''
      ${pkgs.libnotify}/bin/notify-send -t 2000 Clips "Clip saved"
    '';

    clip = pkgs.writeShellApplication {
      name = "clip";
      runtimeInputs = [pkgs.libnotify];
      text = ''
        systemctl --user kill -s USR1 --kill-whom=main ${service} \
          || notify-send -u critical Clips "Replay isn't running"
      '';
    };
  in {
    systemd.user.services.${service} = {
      Unit = {
        Description = "instant replay";
        After = ["graphical-session.target" "pipewire.service"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${clipDir}";
        ExecStart = lib.escapeShellArgs [
          "${gpu-screen-recorder}/bin/gpu-screen-recorder"
          "-w"
          "HDMI-A-1"
          "-s"
          "1920x1080"
          "-f"
          "60"
          "-fm"
          "cfr"
          "-r"
          "120"
          "-c"
          "mp4"
          "-k"
          "h264"
          "-bm"
          "cbr"
          "-q"
          "12000"
          "-a"
          "default_output|default_input"
          "-sc"
          "${saved}"
          "-o"
          clipDir
        ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    wayland.windowManager.hyprland.extraLuaFiles.clips = lib.mkIf (config.wm == "hyprland") {
      autoLoad = true;
      content = ''
        hl.bind("SUPER + X", hl.dsp.exec_cmd("${lib.getExe clip}"))
      '';
    };
  };
}
