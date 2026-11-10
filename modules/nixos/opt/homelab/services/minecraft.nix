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

    systemd.services.minecraft = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        User = "minecraft";
        Group = "minecraft";
        WorkingDirectory = dir;
        ExecStart = "${pkgs.jdk21_headless}/bin/java -Xms6G -Xmx12G @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui";
        Restart = "on-failure";
        TimeoutStopSec = "5min";
      };
    };
  };
}
