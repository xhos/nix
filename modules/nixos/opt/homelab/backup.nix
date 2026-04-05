{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homelab.backup;
  serviceBackups = lib.filterAttrs (_: v: v.paths != []) cfg.services;
  tgNotify = config.homelab.tg-notify.package;
in {
  options.homelab.backup = {
    defaultRepository = lib.mkOption {
      type = lib.types.str;
      default = "rclone:onedrive:restic-backups";
    };
    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          databases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "postgres databases to dump before this backup runs";
          };
        };
      });
      default = {};
    };
  };

  config = lib.mkIf (serviceBackups != {}) {
    systemd.tmpfiles.rules = [
      "d /var/lib/restic 0700 root root -"
      "C /var/lib/restic/rclone.conf 0600 root root - ${config.sops.secrets."rclone".path}"
      "d /var/backup/postgresql 0750 postgres postgres -"
    ];

    persist.dirs = ["/var/backup/postgresql"];

    sops.secrets = {
      "passwords/restic".mode = "0444";
      "rclone".mode = "0444";
    };

    services.restic.backups =
      lib.mapAttrs (name: svc: {
        paths = svc.paths ++ lib.optionals (svc.databases != []) ["/var/backup/postgresql"];
        inherit (svc) exclude;
        user = "root";
        repository = cfg.defaultRepository;
        passwordFile = config.sops.secrets."passwords/restic".path;
        rcloneConfigFile = "/var/lib/restic/rclone.conf";
        initialize = true;
        createWrapper = true;
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
      })
      serviceBackups;

    systemd.services = lib.mkMerge [
      # per-service db dumps
      (lib.mapAttrs' (
          name: svc:
            lib.nameValuePair "restic-dump-${name}" {
              enable = svc.databases != [];
              description = "Dump databases for ${name} backup";
              serviceConfig = {
                Type = "oneshot";
                User = "postgres";
                ExecStart = pkgs.writeShellScript "dump-${name}" ''
                  mkdir -p /var/backup/postgresql
                  ${lib.concatMapStringsSep "\n" (db: ''
                      ${config.services.postgresql.package}/bin/pg_dump \
                        -d ${db} \
                        -f /var/backup/postgresql/${db}.sql
                    '')
                    svc.databases}
                '';
              };
            }
        )
        serviceBackups)

      # wire dump before backup
      (lib.mapAttrs' (
          name: svc:
            lib.nameValuePair "restic-backups-${name}" (
              lib.mkIf (svc.databases != []) {
                requires = ["restic-dump-${name}.service"];
                after = ["restic-dump-${name}.service"];
              }
            )
        )
        serviceBackups)

      # tg-notify
      (lib.mkIf config.homelab.tg-notify.enable (
        lib.mapAttrs' (
          name: _:
            lib.nameValuePair "restic-backups-${name}" {
              serviceConfig.ExecStopPost = lib.mkAfter [
                (pkgs.writeShellScript "restic-${name}-notify" ''
                  if [ "$EXIT_STATUS" != "0" ]; then
                    ${tgNotify}/bin/tg-notify "restic backup <b>${name}</b> failed on $(${pkgs.inetutils}/bin/hostname) (exit $EXIT_STATUS)"
                  fi
                '')
              ];
            }
        )
        serviceBackups
      ))
    ];
  };
}
