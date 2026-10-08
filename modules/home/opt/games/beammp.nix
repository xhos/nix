# BeamMP launcher for BeamNG.drive (steam app 284160), run inside steam-run.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.games.beammp;

  # Steam's library app index can lag behind a newly installed game.
  launcher = pkgs.beammp-launcher.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/Security/BeamNG.cpp \
          --replace-fail '(folderInfo.second->childs["apps"]->attribs).contains("284160") && ' ""
      '';
  });

  beammp = pkgs.writeShellApplication {
    name = "beammp";
    runtimeInputs = [pkgs.steam-run];
    text = ''
      state="''${XDG_DATA_HOME:-$HOME/.local/share}/BeamMP"
      mkdir -p "$state"
      cd "$state"
      exec steam-run ${launcher}/bin/BeamMP-Launcher --no-update "$@"
    '';
  };
in {
  options.games.beammp.enable = lib.mkEnableOption "BeamMP launcher for BeamNG.drive";

  config = lib.mkIf cfg.enable {
    home.packages = [beammp];

    xdg.desktopEntries.beammp = {
      name = "BeamMP";
      exec = "${beammp}/bin/beammp";
      icon = "steam_icon_284160";
      categories = ["Game"];
      terminal = true;
    };

    persist.dirs = [
      ".local/share/BeamMP"
      ".local/share/BeamNG"
    ];
  };
}
