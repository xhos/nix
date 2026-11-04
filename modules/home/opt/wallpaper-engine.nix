{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.wallpaperEngine;

  id = toString cfg.wallpaper;
  source = "${config.home.homeDirectory}/.local/share/Steam/steamapps/workshop/content/431960/${id}";
  cropDir = screen: "${config.xdg.cacheHome}/wallpaper-engine/${id}-${screen}-${lib.replaceStrings [":"] ["-"] cfg.crops.${screen}}";

  mkCrop = pkgs.writeShellApplication {
    name = "wallpaper-engine-crop";
    runtimeInputs = with pkgs; [ffmpeg jq];
    text = ''
      src=$1 dst=$2 crop=$3
      if [[ -f "$dst/project.json" ]]; then exit 0; fi

      mkdir -p "$(dirname "$dst")"
      tmp=$(mktemp -d "$dst.XXXXXX")
      trap 'rm -rf "$tmp"' EXIT

      ffmpeg -nostdin -v error -y -i "$src/$(jq -r .file "$src/project.json")" \
        -vf "crop=$crop" -an -c:v libx264 -preset veryfast -crf 18 "$tmp/video.mp4"
      jq '.file = "video.mp4"' "$src/project.json" > "$tmp/project.json"
      mv "$tmp" "$dst"
    '';
  };

  screens = lib.concatMap (screen: [
    "--screen-root"
    screen
    "--bg"
    (
      if cfg.crops ? ${screen}
      then cropDir screen
      else id
    )
    "--scaling"
    cfg.scaling
  ])
  cfg.screens;

  args = ["--silent" "--fps" (toString cfg.fps) "--assets-dir" cfg.assetsDir] ++ screens;
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
        ExecStartPre =
          lib.mapAttrsToList (
            screen: crop: lib.escapeShellArgs [(lib.getExe mkCrop) source (cropDir screen) crop]
          )
          cfg.crops;
        ExecStart = lib.escapeShellArgs ([(lib.getExe pkgs.linux-wallpaperengine)] ++ args);
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
