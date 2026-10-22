{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homelab.postgres;
  pg = config.services.postgresql.package;
  dumpDir = "/var/backup/postgresql";
  databases = lib.unique config.services.postgresql.ensureDatabases;
in {
  options.homelab.postgres.enable = lib.mkEnableOption "shared postgres server for homelab services";

  config = lib.mkMerge [
    # services pull postgres in implicitly; make sure it only runs through here
    (lib.mkIf config.homelab.enable {
      assertions = [
        {
          assertion = config.services.postgresql.enable -> cfg.enable;
          message = "a service enabled postgres implicitly; set homelab.postgres.enable";
        }
      ];
    })

    (lib.mkIf cfg.enable {
      services.postgresql = {
        enable = true;
        # majors need a manual pg_upgrade, never bump this without one
        package = pkgs.postgresql_16;

        # sockets only, every client authenticates by unix user
        enableTCPIP = false;
        authentication = lib.mkForce ''
          local all postgres peer map=postgres
          local all all      peer
        '';

        settings = {
          listen_addresses = lib.mkForce "";

          shared_buffers = "2GB";
          effective_cache_size = "8GB";
          work_mem = "16MB";
          maintenance_work_mem = "512MB";
          random_page_cost = 1.1;
          effective_io_concurrency = 200;
          wal_compression = "zstd";

          log_min_duration_statement = "1s";
          log_checkpoints = true;
          log_lock_waits = true;
        };
      };

      persist.dirs = ["/var/lib/postgresql" dumpDir];

      systemd.tmpfiles.rules = ["d ${dumpDir} 0750 postgres postgres -"];

      # every db on the server gets dumped, so new services can't be forgotten
      homelab.backup.services.postgres.paths = [dumpDir];

      systemd.services.postgres-dump = {
        description = "Dump all postgres databases";
        requires = ["postgresql.target"];
        after = ["postgresql.target"];
        serviceConfig = {
          Type = "oneshot";
          User = "postgres";
          Group = "postgres";
          UMask = "0027";
        };
        script = ''
          set -euo pipefail
          cd ${dumpDir}
          rm -f *.tmp
          ${pg}/bin/pg_dumpall --globals-only -f globals.sql.tmp
          mv globals.sql.tmp globals.sql
          ${lib.concatMapStringsSep "\n" (db: ''
              ${pg}/bin/pg_dump -Fc -d ${lib.escapeShellArg db} -f ${lib.escapeShellArg "${db}.dump.tmp"}
              mv ${lib.escapeShellArg "${db}.dump.tmp"} ${lib.escapeShellArg "${db}.dump"}
            '')
            databases}
          # drop dumps of databases that no longer exist
          for f in *.dump *.sql; do
            case "$f" in
              globals.sql ${lib.concatMapStrings (db: "| ${lib.escapeShellArg "${db}.dump"} ") databases}) ;;
              *) rm -f -- "$f" ;;
            esac
          done
        '';
      };

      systemd.services.restic-backups-postgres = {
        requires = ["postgres-dump.service"];
        after = ["postgres-dump.service"];
      };
    })
  ];
}
