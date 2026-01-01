{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    "syncthing/enrai/cert" = {
      owner = config.services.syncthing.user;
      mode = "0400";
    };
    "syncthing/enrai/key" = {
      owner = config.services.syncthing.user;
      mode = "0400";
    };
    "syncthing/enrai/guiPassword" = {
      owner = config.services.syncthing.user;
      mode = "0400";
    };
  };

  _enrai.exposedServices.syncthing.port = 8384;

  services.syncthing = {
    enable = true;
    user = "xhos";
    dataDir = "/home/xhos/.local/share/syncthing";
    key = config.sops.secrets."syncthing/enrai/key".path;
    cert = config.sops.secrets."syncthing/enrai/cert".path;
    guiAddress = "${config._enrai.config.enraiLocalIP}:8384";

    # TODO: yet to be released
    # guiPasswordFile = config.sops.secrets."syncthing/enrai/guiPassword".path;

    settings = {
      options.urAccepted = -1;
      gui = {
        user = "xhos";
        password = "$2b$12$mXEJ2ZnOFfk9VvANdQKjdOvRHqeBFxT6h0BF1EavsThTGQADZAiHK";
      };

      # device id can be found in client's ui or
      # nix-shell -p syncthing --run "syncthing generate --home /tmp/st"
      devices."pixel".id = "C2YDFEG-D732HTB-QCIKZAO-XIBSQWH-JEDHE7U-IDGRUFJ-2YOIVBK-HJCNPAQ";
      devices."vyverne".id = "ZKQ5CJE-DITDIVT-26MO4CP-V2QSMQS-JWBGY2T-7DOOHAD-5LVZ2ZF-SGLOPAG";
      devices."zireael".id = "ED6PFOE-52HGHJV-7WM2GQX-676UIGS-7X23A36-WTALXEO-2W76URW-OFTKBQM";

      folders = {
        "notes" = {
          path = "/home/xhos/Documents/notes";
          devices = ["pixel" "vyverne" "zireael"];
        };
      };
    };
  };

  systemd.services.notes-git-sync = {
    description = "sync notes with git";
    path = [pkgs.git pkgs.openssh];
    serviceConfig = {
      Type = "oneshot";
      User = "xhos";
      WorkingDirectory = "/home/xhos/Documents/notes";
      ExecStart = pkgs.writeShellScript "sync-notes" ''
        set -e

        git pull --rebase --autostash || {
          git rebase --abort 2>/dev/null || true
          git pull --no-rebase --autostash
        }

        git add -A
        git commit -m "auto-sync from enrai $(date '+%Y-%m-%d %H:%M')" || true

        git push
      '';
    };
  };

  systemd.timers.notes-git-sync = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/15";
      Persistent = true;
    };
  };
}
