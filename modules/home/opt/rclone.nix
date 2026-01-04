{
  pkgs,
  config,
  lib,
  ...
}:
let
  # theese need to be created manually
  onedriveDir = "/home/xhos/onedrive";
  username = "xhos";
in {
  options.rclone.enable = lib.mkEnableOption "rclone cloud storage mount (onedrive)";
  config = lib.mkIf config.rclone.enable {
    persist.dirs = [ onedriveDir ];
    sops.secrets.rclone.path = "/home/${username}/.config/rclone/rclone.conf";
    environment.systemPackages = with pkgs; [rclone];

    systemd.services.rclone-onedrive-mount = {
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      requires = ["network-online.target"];

      serviceConfig = {
        Type = "simple";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${onedriveDir}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --vfs-cache-mode full onedrive: ${onedriveDir}";
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${onedriveDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        User = username;
        Group = "users";
        Environment = ["PATH=/run/wrappers/bin/:$PATH"];
      };
    };
  };
}
