# Modded Valheim dedicated server. The mod tree is built from a Thunderstore
# (r2modman) profile code as a fixed-output derivation; the game itself is
# installed/updated by steamcmd at runtime so it tracks what clients run.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.valheim;
  root = "/var/lib/valheim";
  game = "${root}/server";
  saves = "${root}/saves";
  generatedPassword = "${root}/password";

  # fixed-output paths are reused when name and hash match, so every input
  # has to be in the name or a stale hash would silently keep the old pack
  modpackName =
    "valheim-modpack-${cfg.code}"
    + lib.optionalString (cfg.exclude != []) "-${builtins.substring 0 8 (builtins.hashString "sha256" (toString cfg.exclude))}";

  modpack =
    pkgs.runCommand modpackName {
      nativeBuildInputs = [pkgs.curl (pkgs.python3.withPackages (p: [p.pyyaml]))];
      impureEnvVars = lib.fetchers.proxyImpureEnvVars;
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = cfg.hash;
    } ''
      # nix points SSL_CERT_FILE at a dummy in fixed-output builds
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      python3 ${./valheim-modpack.py} ${lib.escapeShellArg cfg.code} "$out" ${lib.escapeShellArgs cfg.exclude}
    '';

  prepare = pkgs.writeShellScript "valheim-prepare" ''
    set -euo pipefail
    ${lib.optionalString (cfg.passwordFile == null) ''
      if [ ! -s ${generatedPassword} ]; then
        (umask 027; ${lib.getExe pkgs.openssl} rand -hex 8 > ${generatedPassword})
      fi
    ''}

    # managed mod dirs are replaced wholesale; config files from the profile are
    # overwritten, configs that mods generate on first start are left alone
    cd ${game}
    rm -rf BepInEx/core BepInEx/plugins BepInEx/patchers BepInEx/monomod doorstop_libs
    cp -rT --no-preserve=mode ${modpack} .
  '';

  run = pkgs.writeShellScript "valheim-run" ''
    set -euo pipefail
    password="$(cat ${
      if cfg.passwordFile == null
      then generatedPassword
      else "\"$CREDENTIALS_DIRECTORY/password\""
    })"
    exec ${lib.getExe pkgs.steam-run} env \
      DOORSTOP_ENABLED=1 \
      DOORSTOP_TARGET_ASSEMBLY=./BepInEx/core/BepInEx.Preloader.dll \
      LD_LIBRARY_PATH=./doorstop_libs:./linux64 \
      LD_PRELOAD=libdoorstop_x64.so \
      SteamAppId=892970 \
      ./valheim_server.x86_64 \
      -nographics -batchmode \
      -name ${lib.escapeShellArg cfg.name} \
      -port ${toString cfg.port} \
      -world ${lib.escapeShellArg cfg.world} \
      -password "$password" \
      -savedir ${saves} \
      -public 0 \
      ${lib.escapeShellArgs cfg.extraArgs}
  '';

  ports = "{ ${toString cfg.port}, ${toString (cfg.port + 1)} }";
in {
  options.homelab.valheim = {
    enable = lib.mkEnableOption "modded Valheim dedicated server";

    code = lib.mkOption {
      type = lib.types.strMatching "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";
      example = "01a0ea13-a907-cf31-43bd-524e6e33ff36";
      description = "r2modman / Thunderstore profile code (Settings > Export profile as code)";
    };

    hash = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Hash of the built modpack. Leave empty, build, and paste the hash nix reports";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["MaxiMods-MultiCraft"];
      description = "Client-only packages (Author-Name) to leave off the server. Changes the hash";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "xhos";
      description = "Server name shown to players";
    };

    world = lib.mkOption {
      type = lib.types.str;
      default = "enrai";
      description = "World name; created on first start";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 2456;
      description = "Game port; port + 1 is used for the Steam query port";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Server password (min 5 chars, not part of the name). Generated in ${generatedPassword} when null";
    };

    public = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Forward the game ports from proxy-1";
    };

    allowedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["zt*"];
      description = "Extra interfaces (nftables iifname patterns) allowed to reach the game ports; tailscale is always allowed";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["-crossplay"];
      description = "Extra valheim_server arguments";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.valheim = {
      isSystemUser = true;
      group = "valheim";
      home = root;
    };
    users.groups.valheim = {};
    users.users.xhos.extraGroups = ["valheim"];

    persist.dirs = [root];
    homelab.backup.services.valheim.paths = [saves];

    homelab.firewall.extraInputRules = lib.concatMapStrings (iface: ''
      iifname "${iface}" udp dport ${ports} accept
    '')
    cfg.allowedInterfaces;

    homelab.tcpForwards = lib.mkIf cfg.public (lib.listToAttrs (map (port:
      lib.nameValuePair "valheim-${toString port}" {
        listen = port;
        inherit port;
        proto = "udp";
      }) [cfg.port (cfg.port + 1)]));

    systemd.services.valheim-update = {
      description = "Install or update the Valheim dedicated server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      environment.HOME = root;
      serviceConfig = {
        Type = "oneshot";
        User = "valheim";
        Group = "valheim";
        StateDirectory = "valheim";
        StateDirectoryMode = "0750";
        ExecStart = "${lib.getExe pkgs.steamcmd} +force_install_dir ${game} +login anonymous +app_update 896660 +quit";
        TimeoutStartSec = "30min";
      };
    };

    systemd.services.valheim = {
      description = "Modded Valheim dedicated server";
      wantedBy = ["multi-user.target"];
      # a restart re-runs the update so the server keeps up with client patches
      wants = ["valheim-update.service"];
      after = ["valheim-update.service"];
      restartTriggers = [modpack];
      environment.HOME = root;
      serviceConfig = {
        User = "valheim";
        Group = "valheim";
        StateDirectory = "valheim";
        StateDirectoryMode = "0750";
        WorkingDirectory = game;
        LoadCredential = lib.optional (cfg.passwordFile != null) "password:${cfg.passwordFile}";
        ExecStartPre = prepare;
        ExecStart = run;
        Restart = "on-failure";
        RestartSec = 10;
        # SIGINT makes the server save the world before exiting
        KillSignal = "SIGINT";
        TimeoutStopSec = "2min";
      };
    };
  };
}
