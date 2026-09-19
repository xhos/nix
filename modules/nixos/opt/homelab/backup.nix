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
      "d /var/backup/postgresql 0750 postgres postgres -"
    ];

    persist.dirs = ["/var/backup/postgresql"];

    sops.secrets = {
      "passwords/restic" = {};
      "api/backblaze/id" = {};
      "api/backblaze/key" = {};
      "api/backblaze/name" = {};
    };

    sops.templates = {
      restic-b2-env.content = ''
        B2_ACCOUNT_ID=${config.sops.placeholder."api/backblaze/id"}
        B2_ACCOUNT_KEY=${config.sops.placeholder."api/backblaze/key"}
      '';
      restic-repo.content = "b2:${config.sops.placeholder."api/backblaze/name"}:";
    };

    services.restic.backups =
      lib.mapAttrs (name: svc: {
        paths = svc.paths ++ lib.optionals (svc.databases != []) ["/var/backup/postgresql"];
        inherit (svc) exclude;
        user = "root";
        repositoryFile = config.sops.templates.restic-repo.path;
        passwordFile = config.sops.secrets."passwords/restic".path;
        environmentFile = config.sops.templates.restic-b2-env.path;
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
              requires = ["postgresql.service"];
              after = ["postgresql.service"];
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
