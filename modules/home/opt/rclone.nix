{
  pkgs,
  config,
  lib,
  ...
}:
let
  onedriveDir = "/home/xhos/onedrive";
  username = "xhos";
in {
  options.modules.rclone.enable = lib.mkEnableOption "rclone cloud storage mount (onedrive)";
  
  config = lib.mkIf config.modules.rclone.enable {
    persist.dirs = [ onedriveDir ];
    sops.secrets.rclone.path = "/home/${username}/.config/rclone/rclone.conf";
    home.packages = with pkgs; [ rclone ];
    
    systemd.user.services.rclone-onedrive-mount = {
      Unit = {
        Description = "rclone OneDrive mount";
        After = [ "default.target" ];  # Just wait for user session to be ready
      };
      
      Service = {
        Type = "simple";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${onedriveDir}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --vfs-cache-mode full onedrive: ${onedriveDir}";
        ExecStop = "/run/current-system/sw/bin/fusermount -u ${onedriveDir}";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = "PATH=/run/wrappers/bin/:$PATH";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}