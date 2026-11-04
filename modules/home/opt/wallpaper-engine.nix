{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.wallpaperEngine;

  id = toString cfg.wallpaper;
  source = "${config.home.homeDirectory}/.local/share/Steam/steamapps/workshop/content/431960/${id}";
  crop = screen: cfg.crops.${screen} or "";
  copyDir = screen: "${config.xdg.cacheHome}/wallpaper-engine/${id}-${
    if crop screen == ""
    then "full"
    else lib.replaceStrings [":"] ["-"] (crop screen)
  }";

  # --silent only zeroes the volume, a video with an audio track still shows up in mixers
  prepare = pkgs.writeShellApplication {
    name = "wallpaper-engine-prepare";
    runtimeInputs = with pkgs; [coreutils ffmpeg jq];
    text = ''
      src=$1 dst=$2 crop=''${3:-}
      if [[ -f "$dst/project.json" ]]; then exit 0; fi

      mkdir -p "$(dirname "$dst")"
      if [[ $(jq -r '.type | ascii_downcase' "$src/project.json") != video ]]; then
        ln -sfn "$src" "$dst"
        exit 0
      fi

      file=$(jq -r .file "$src/project.json")
      out="video.''${file##*.}"
      video=(-c:v copy)
      if [[ -n $crop ]]; then
        video=(-vf "crop=$crop" -c:v libx264 -preset veryfast -crf 18)
      fi

      tmp=$(mktemp -d "$dst.XXXXXX")
      trap 'rm -rf "$tmp"' EXIT
      ffmpeg -nostdin -v error -y -i "$src/$file" -an "''${video[@]}" "$tmp/$out"
      jq --arg out "$out" '.file = $out' "$src/project.json" > "$tmp/project.json"
      mv "$tmp" "$dst"
    '';
  };

  screens = lib.concatMap (screen: [
    "--screen-root"
    screen
    "--bg"
    (copyDir screen)
    "--scaling"
    cfg.scaling
  ])
  cfg.screens;

  args = ["--silent" "--no-audio-processing" "--fps" (toString cfg.fps) "--assets-dir" cfg.assetsDir] ++ screens;
in {
  options.modules.wallpaperEngine = with lib; {
    enable = mkEnableOption "live wallpapers via linux-wallpaperengine";

    wallpaper = mkOption {
      type = types.int;
      description = "workshop id, must be subscribed to in steam";
    };

    screens = mkOption {
      type = types.listOf types.str;
      description = "output names, one instance of the wallpaper per screen";
    };

    # linux-wallpaperengine can only center, so other framings need a cropped copy
    crops = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {"HDMI-A-2" = "608:1080:0:0";};
      description = "ffmpeg crop (w:h:x:y) per screen, video wallpapers only";
    };

    scaling = mkOption {
      type = types.enum ["stretch" "fit" "fill" "default"];
      default = "fill";
    };

    fps = mkOption {
      type = types.int;
      default = 30;
    };

    assetsDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/wallpaper_engine/assets";
      description = "assets folder of the steam wallpaper engine install";
    };
  };

  # sits above hyprpaper, so the static wallpaper shows if this isn't running
  config = lib.mkIf cfg.enable {
    systemd.user.services.linux-wallpaperengine = {
      Unit = {
        Description = "live wallpaper";
        After = ["graphical-session.target" "hyprpaper.service"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStartPre = map (
          screen: lib.escapeShellArgs [(lib.getExe prepare) source (copyDir screen) (crop screen)]
        )
        cfg.screens;
        Environment = ["SDL_AUDIODRIVER=dummy" "SDL_AUDIO_DRIVER=dummy"];
        ExecStart = lib.escapeShellArgs ([(lib.getExe pkgs.linux-wallpaperengine)] ++ args);
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
