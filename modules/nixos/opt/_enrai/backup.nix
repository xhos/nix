{
  config,
  lib,
  ...
}: let
  cfg = config._enrai.backup;
  serviceBackups = lib.filterAttrs (_: v: v.paths != []) cfg.services;
in {
  options._enrai.backup = {
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
        };
      });
      default = {};
    };
  };

  config = lib.mkIf (serviceBackups != {}) {
    users.users.restic = {
      isSystemUser = true;
      group = "restic";
    };
    users.groups.restic = {};

    sops.secrets = {
      "passwords/restic" = {
        owner = "restic"; 
        group = "restic"; 
      };
      "rclone" = {
        owner = "restic";
        group = "restic"; 
      };
    };

    services.restic.backups =
      lib.mapAttrs (name: svc: {
        inherit (svc) paths exclude;
        user = "restic";
        repository = cfg.defaultRepository;
        passwordFile = config.sops.secrets."passwords/restic".path;
        rcloneConfigFile = config.sops.secrets."rclone".path;
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
  };
}
