{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.homelab.backup;
  serviceBackups = lib.filterAttrs (_: v: v.paths != []) cfg.services;
  tgNotify = config.homelab.tg-notify.package;
  notify = unit: msg:
    pkgs.writeShellScript "${unit}-notify" ''
      if [ "$EXIT_STATUS" != "0" ]; then
        ${tgNotify}/bin/tg-notify "${msg} on $(${pkgs.inetutils}/bin/hostname) (exit $EXIT_STATUS)"
      fi
    '';
  # catches backups that silently stopped running, not just failed ones
  staleCheck = pkgs.writeShellScript "restic-stale-check" ''
    set -uo pipefail
    # one listing for all services, so a network blip isn't reported as stale backups
    snaps=$(${pkgs.restic}/bin/restic snapshots --json --no-lock) || { echo "could not list snapshots"; exit 1; }
    now=$(date +%s)
    stale=()
    ${lib.concatStrings (lib.mapAttrsToList (name: svc: ''
        t=$(${pkgs.jq}/bin/jq -r --argjson want ${lib.escapeShellArg (builtins.toJSON svc.paths)} \
          'map(select($want - .paths == []) | .time) | max // empty' <<<"$snaps")
        if [ -z "$t" ] || [ $((now - $(date -d "$t" +%s))) -gt ${toString cfg.maxAge} ]; then
          stale+=(${name})
        fi
      '')
      serviceBackups)}
    if [ ''${#stale[@]} -gt 0 ]; then
      echo "stale backups: ''${stale[*]}"
      exit 1
    fi
  '';
  repoEnv = {
    RESTIC_REPOSITORY_FILE = config.sops.templates.restic-repo.path;
    RESTIC_PASSWORD_FILE = config.sops.secrets."passwords/restic".path;
    RESTIC_CACHE_DIR = "/var/cache/restic-check";
  };
in {
  options.homelab.backup = {
    maxAge = lib.mkOption {
      type = lib.types.int;
      default = 2 * 24 * 3600;
      description = "seconds since a service's latest snapshot before it counts as stale";
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
          timerConfig = lib.mkOption {
            type = lib.types.attrs;
            default = {
              OnCalendar = "daily";
              Persistent = true;
              RandomizedDelaySec = "1h";
            };
          };
          keep = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6"];
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
        inherit (svc) paths exclude timerConfig;
        user = "root";
        repositoryFile = config.sops.templates.restic-repo.path;
        passwordFile = config.sops.secrets."passwords/restic".path;
        environmentFile = config.sops.templates.restic-b2-env.path;
        initialize = true;
        createWrapper = true;
        extraBackupArgs = ["--retry-lock 3h"];
        # the repo is shared, so only forget this service's own snapshots
        pruneOpts = svc.keep ++ map (p: "--path ${p}") svc.paths ++ ["--retry-lock 3h"];
      })
      serviceBackups;

    systemd.services = lib.mkMerge [
      {
        # repo is shared, so one check covers every service
        restic-check = {
          wants = ["network-online.target"];
          after = ["network-online.target"];
          description = "Verify restic repository integrity";
          environment = repoEnv;
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = config.sops.templates.restic-b2-env.path;
            CacheDirectory = "restic-check";
            ExecStart = "${pkgs.restic}/bin/restic check --read-data-subset=5% --retry-lock 3h";
            ExecStopPost = lib.mkIf config.homelab.tg-notify.enable "${notify "restic-check" "restic check <b>failed</b>"}";
          };
        };
      }
      {
        restic-stale-check = {
          wants = ["network-online.target"];
          after = ["network-online.target"];
          description = "Alert on restic backups that stopped running";
          environment = repoEnv;
          path = [pkgs.coreutils];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = config.sops.templates.restic-b2-env.path;
            CacheDirectory = "restic-check";
            ExecStart = "${staleCheck}";
            ExecStopPost = lib.mkIf config.homelab.tg-notify.enable "${notify "restic-stale-check" "restic backups are <b>stale</b>, check restic-stale-check logs"}";
          };
        };
      }
      (lib.mkIf config.homelab.tg-notify.enable (
        lib.mapAttrs' (
          name: _:
            lib.nameValuePair "restic-backups-${name}" {
              serviceConfig.ExecStopPost = lib.mkAfter ["${notify "restic-${name}" "restic backup <b>${name}</b> failed"}"];
            }
        )
        serviceBackups
      ))
    ];

    systemd.timers.restic-stale-check = {
      wantedBy = ["timers.target"];
      timerConfig = {
        # no catch-up at boot, backups need a chance to run first
        OnCalendar = "12:00";
      };
    };

    systemd.timers.restic-check = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "Sun 13:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
