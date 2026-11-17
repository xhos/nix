{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.minecraft;
  dir = cfg.dataDir;
  snap = "${dir}-snapshot";
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
    users.users.xhos.extraGroups = ["minecraft"];

    systemd.tmpfiles.rules = [
      "d ${dir} 0750 minecraft minecraft -"
      "d ${snap} 0700 root root -"
    ];
    # hourly, without pausing the game: stop autosave, flush, rsync to a
    # staging copy, resume saving, then restic uploads the copy at leisure
    homelab.backup.services.minecraft = {
      paths = [snap];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
      keep = ["--keep-hourly 24" "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6"];
    };
    services.restic.backups.minecraft = {
      backupPrepareCommand = ''
        console() { echo "$*" > /run/minecraft.stdin; }
        if systemctl -q is-active minecraft; then
          trap 'console save-on' EXIT
          cursor=$(journalctl -u minecraft -n0 --show-cursor -o cat | sed -n 's/^-- cursor: //p')
          console save-off
          console save-all flush
          timeout 300 sh -c "until journalctl -u minecraft --after-cursor='$cursor' -o cat | grep -q 'Saved the world'; do sleep 1; done"
        fi
        ${pkgs.rsync}/bin/rsync -a --delete --exclude /backups --exclude /logs --exclude /backup-latest ${dir}/ ${snap}/
      '';
    };

    # server console on a fifo, e.g. `mc whitelist add name`
    systemd.sockets.minecraft = {
      bindsTo = ["minecraft.service"];
      socketConfig = {
        ListenFIFO = "/run/minecraft.stdin";
        SocketMode = "0660";
        SocketUser = "minecraft";
        SocketGroup = "minecraft";
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "mc" ''
        echo "$*" > /run/minecraft.stdin
        sleep 1
        journalctl -u minecraft -n 5 --no-pager -o cat
      '')
    ];

    systemd.services.minecraft = {
      wantedBy = ["multi-user.target"];
      after = ["network.target" "minecraft.socket"];
      requires = ["minecraft.socket"];
      serviceConfig = {
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";
        User = "minecraft";
        Group = "minecraft";
        WorkingDirectory = dir;
        ExecStart = "${pkgs.jdk21_headless}/bin/java -Xms6G -Xmx16G -Duser.language=en @java9args.txt -jar lwjgl3ify-forgePatches.jar nogui";
        # sigterm makes forge's shutdown hook throw mid-save, so use the console
        ExecStop = pkgs.writeShellScript "minecraft-stop" ''
          echo stop > /run/minecraft.stdin
          while kill -0 "$MAINPID" 2>/dev/null; do sleep 1; done
        '';
        Restart = "on-failure";
        RestartSec = 15;
        TimeoutStopSec = "5min";
      };
    };
  };
}
