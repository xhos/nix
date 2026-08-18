{
  pkgs,
  config,
  lib,
  ...
}: let
  username = "xhos";
  home = "/home/${username}";

  mountDir = "${home}/proton";
  stateDir = "${home}/.local/state/rclone";
  configFile = "${stateDir}/rclone.conf";

  flags = lib.concatStringsSep " " [
    "--config ${configFile}"
    "--vfs-cache-mode full"
    "--vfs-cache-max-age 24h"
    "--vfs-cache-max-size 10G"
    "--dir-cache-time 1h"
    "--poll-interval 0" # protondrive has no event system, polling is wasted api calls
    "--umask 022"
    "--log-level INFO"
  ];

  preStart = pkgs.writeShellScript "rclone-proton-pre" ''
    mkdir -p ${mountDir} ${stateDir}
    if [ ! -e ${configFile} ]; then
      install -m 0600 ${config.sops.secrets.rclone.path} ${configFile}
    fi
  '';
in {
  options.modules.rclone.enable = lib.mkEnableOption "rclone Proton Drive mount";

  config = lib.mkIf config.modules.rclone.enable {
    persist.dirs = [".local/state/rclone"];

    sops.secrets.rclone = {};

    home.packages = [pkgs.rclone];

    systemd.user.services.rclone-proton = {
      Unit = {
        Description = "rclone Proton Drive mount";
        After = ["sops-nix.service"];
        Wants = ["sops-nix.service"];
      };
      Service = {
        Type = "notify";
        ExecStartPre = "${preStart}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount ${flags} protondrive: ${mountDir}";
        ExecStop = "/run/wrappers/bin/fusermount -uz ${mountDir}";
        Environment = ["PATH=/run/wrappers/bin"];
        Restart = "on-failure";
        RestartSec = "30s"; # proton throttles and captchas aggressive retries
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
