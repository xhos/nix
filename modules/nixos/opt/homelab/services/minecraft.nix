{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.minecraft;
  dir = cfg.dataDir;
in {
  options.homelab.minecraft = {
    enable = lib.mkEnableOption "GTNH minecraft server";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/minecraft";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.minecraft = {
      isSystemUser = true;
      group = "minecraft";
      home = dir;
    };
    users.groups.minecraft = {};

    systemd.tmpfiles.rules = ["d ${dir} 0750 minecraft minecraft -"];
    homelab.backup.services.minecraft = {
      paths = [dir];
      exclude = ["${dir}/backups" "${dir}/logs"];
    };
    # the live world can be mid-write, so also ship the newest finished
    # serverutilities zip; a hardlink keeps it free and out of the rotation
    services.restic.backups.minecraft.backupPrepareCommand = ''
      latest=$(find ${dir}/backups -name '*.zip' -mmin +5 -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
      rm -rf ${dir}/backup-latest
      if [ -n "$latest" ]; then
        mkdir -p ${dir}/backup-latest
        ln "$latest" ${dir}/backup-latest/
      fi
    '';

    systemd.services.minecraft = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        User = "minecraft";
        Group = "minecraft";
        WorkingDirectory = dir;
        ExecStart = "${pkgs.jdk21_headless}/bin/java -Xms6G -Xmx16G -Duser.language=en @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui";
        Restart = "on-failure";
        RestartSec = 15;
        TimeoutStopSec = "5min";
      };
    };
  };
}
