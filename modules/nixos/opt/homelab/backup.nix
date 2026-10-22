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
        };
      });
      default = {};
    };
  };

  config = lib.mkIf (serviceBackups != {}) {
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
        inherit (svc) paths exclude;
        user = "root";
        repositoryFile = config.sops.templates.restic-repo.path;
        passwordFile = config.sops.secrets."passwords/restic".path;
        environmentFile = config.sops.templates.restic-b2-env.path;
        initialize = true;
        createWrapper = true;
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
        extraBackupArgs = ["--retry-lock 3h"];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
          "--retry-lock 3h"
        ];
      })
      serviceBackups;

    systemd.services = lib.mkIf config.homelab.tg-notify.enable (
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
    );
  };
}
