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

    # runs after the file is written, so this can't report a clip that doesn't exist
    saved = pkgs.writeShellScript "clip-saved" ''
      ${pkgs.libnotify}/bin/notify-send -t 2000 Clips "Clip saved"
    '';

    # connectors move between ports, the monitor description doesn't
    record = pkgs.writeShellApplication {
      name = "clip-record";
      runtimeInputs = [pkgs.hyprland pkgs.jq pkgs.gpu-screen-recorder];
      text = ''
        output=$(hyprctl monitors -j | jq -r --arg d ${lib.escapeShellArg config.mainMonitor} '.[] | select(.description == $d) | .name')
        exec gpu-screen-recorder -w "''${output:-screen}" "$@"
      '';
    };

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
          (lib.getExe record)
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
