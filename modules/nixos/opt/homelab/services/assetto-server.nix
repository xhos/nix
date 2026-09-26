# Assetto Corsa servers (AssettoServer) with AI traffic and Content Manager
# direct downloads. Content (cars/tracks/splines) is mutable and lives outside
# the store; each start builds a symlink farm over it so the source tree stays
# byte-identical to what friends download.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.assetto-server;
  yaml = pkgs.formats.yaml {};
  json = pkgs.formats.json {};

  # AC's INI parser wants 0/1 for booleans
  toINI = lib.generators.toINI {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString = v:
        if lib.isBool v
        then
          (
            if v
            then "1"
            else "0"
          )
        else lib.generators.mkValueStringDefault {} v;
    } "=";
  };

  instanceModule = {name, ...}: {
    options = {
      enable = lib.mkEnableOption "this assetto corsa server instance";

      contentDir = lib.mkOption {
        type = lib.types.str;
        description = "Directory with cars/ and tracks/ exactly as they are distributed to clients";
      };

      track = lib.mkOption {
        type = lib.types.str;
        description = "Track folder name";
      };

      trackLayout = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Track layout (CONFIG_TRACK)";
      };

      trafficSpline = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "AI spline package (.aip) installed as fast_lane.aip for this server only";
      };

      playerCars = lib.mkOption {
        type = lib.types.attrsOf lib.types.ints.positive;
        default = {};
        description = "Car model -> number of player slots";
      };

      trafficCars = lib.mkOption {
        type = lib.types.attrsOf lib.types.ints.positive;
        default = {};
        description = "Car model -> number of AI traffic slots";
      };

      maxPlayers = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 8;
        description = "Soft player limit, keeps the remaining slots for traffic (0 = no limit)";
      };

      playerSlotOffset = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 0;
        description = "Number of traffic entries placed before player entries to select their pit positions";
      };

      pitBoxes = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        description = "Layout pit capacity, checked against all player and traffic entries";
      };

      cspExtraOptions = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = {};
        description = "CSP extra server options (csp_extra_options.ini)";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9600;
        description = "Game port (TCP and UDP)";
      };

      httpPort = lib.mkOption {
        type = lib.types.port;
        default = 8081;
        description = "HTTP port used by Content Manager for details and downloads";
      };

      public = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Forward the game and HTTP ports from proxy-1";
      };

      allowedInterfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["zt*"];
        description = "Extra interfaces (nftables iifname patterns) allowed to reach the game and HTTP ports";
      };

      downloadSpeedLimit = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 4 * 1024 * 1024;
        description = "Per-download bandwidth limit for CM direct downloads in bytes/s (0 = unlimited)";
      };

      serverCfg = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = {};
        description = "server_cfg.ini overrides, merged over the defaults";
      };

      extraCfg = lib.mkOption {
        inherit (yaml) type;
        default = {};
        description = "extra_cfg.yml overrides, merged over the defaults";
      };
    };
  };

  enabled = lib.filterAttrs (_: i: i.enable) cfg.instances;

  stateDir = name: "/var/lib/assetto-server/${name}";
  secret = name: kind: config.sops.secrets."assetto-server/${name}/${kind}".path;

  mkFiles = name: inst: let
    serverCfg = lib.recursiveUpdate {
      SERVER = {
        NAME = "xhos ${name}";
        PASSWORD = "@PASSWORD@";
        ADMIN_PASSWORD = "@ADMIN_PASSWORD@";
        TRACK = inst.track;
        CONFIG_TRACK = inst.trackLayout;
        TCP_PORT = inst.port;
        UDP_PORT = inst.port;
        HTTP_PORT = inst.httpPort;
        REGISTER_TO_LOBBY = false;
        CLIENT_SEND_INTERVAL_HZ = 20;
        LOOP_MODE = true;
        SUN_ANGLE = 64; # ~17:00
        TIME_OF_DAY_MULT = 1;
        ABS_ALLOWED = 1;
        TC_ALLOWED = 1;
        STABILITY_ALLOWED = false;
        AUTOCLUTCH_ALLOWED = true;
        TYRE_BLANKETS_ALLOWED = true;
        FORCE_VIRTUAL_MIRROR = false;
        FUEL_RATE = 0;
        DAMAGE_MULTIPLIER = 0;
        TYRE_WEAR_RATE = 0;
        ALLOWED_TYRES_OUT = -1;
        MAX_CONTACTS_PER_KM = -1;
        RESULT_SCREEN_TIME = 10;
      };
      PRACTICE = {
        NAME = "Free Roam";
        TIME = 720;
        IS_OPEN = 1;
      };
      DYNAMIC_TRACK = {
        SESSION_START = 100;
        RANDOMNESS = 0;
        SESSION_TRANSFER = 100;
        LAP_GAIN = 1;
      };
      WEATHER_0 = {
        GRAPHICS = "3_clear";
        BASE_TEMPERATURE_AMBIENT = 20;
        BASE_TEMPERATURE_ROAD = 8;
        VARIATION_AMBIENT = 2;
        VARIATION_ROAD = 2;
        WIND_BASE_SPEED_MIN = 0;
        WIND_BASE_SPEED_MAX = 2;
        WIND_BASE_DIRECTION = 0;
        WIND_VARIATION_DIRECTION = 20;
      };
    }
    inst.serverCfg;

    playerEntries = lib.concatLists (lib.mapAttrsToList (model: n: lib.replicate n {inherit model; ai = false;}) inst.playerCars);
    trafficEntries = lib.concatLists (lib.mapAttrsToList (model: n: lib.replicate n {inherit model; ai = true;}) inst.trafficCars);
    # Indices must remain contiguous; reuse real traffic slots as the prefix.
    entries = lib.take inst.playerSlotOffset trafficEntries
      ++ playerEntries
      ++ lib.drop inst.playerSlotOffset trafficEntries;

    entryList = lib.listToAttrs (lib.imap0 (i: e:
      lib.nameValuePair "CAR_${toString i}" ({
          MODEL = e.model;
          SKIN = "";
          SPECTATOR_MODE = 0;
          DRIVERNAME = "";
          TEAM = "";
          GUID = "";
          BALLAST = 0;
          RESTRICTOR = 0;
        }
        // lib.optionalAttrs e.ai {AI = "fixed";}))
    entries);

    extraCfg = lib.recursiveUpdate {
      EnableAi = inst.trafficCars != {};
      # traffic slots are declared explicitly in the entry list
      AiParams = {
        AutoAssignTrafficCars = false;
        MaxPlayerCount = inst.maxPlayers;
        TwoWayTraffic = false;
        HideAiCars = true;
      };
      MinimumCSPVersion = 4157;
      EnableServerDetails = true;
      EnableWeatherFx = true;
      EnableCarReset = true;
      RedactIpAddresses = true;
    }
    inst.extraCfg;

    cars = lib.unique (lib.attrNames inst.playerCars ++ lib.attrNames inst.trafficCars);
    # relative to the working directory
    downloads = "downloads";
  in {
    inherit cars downloads;
    serverCfg = pkgs.writeText "server_cfg.ini" (toINI serverCfg);
    entryList = pkgs.writeText "entry_list.ini" (toINI entryList);
    extraCfg = yaml.generate "extra_cfg.yml" extraCfg;
    cspExtraOptions = pkgs.writeText "csp_extra_options.ini" (toINI inst.cspExtraOptions);
    wrapperParams = json.generate "cm_wrapper_params.json" {
      downloadSpeedLimit = inst.downloadSpeedLimit;
      downloadPasswordOnly = true;
    };
    content = json.generate "content.json" {
      cars = lib.genAttrs cars (car: {file = "${downloads}/cars/${car}.zip";});
      track.file = "${downloads}/track.zip";
    };
  };

  mkPrepare = name: inst: let
    f = mkFiles name inst;
    aiParent =
      if inst.trackLayout == ""
      then ""
      else "/${inst.trackLayout}";
  in
    pkgs.writeShellApplication {
      name = "assetto-server-${name}-prepare";
      runtimeInputs = with pkgs; [coreutils findutils zip replace-secret];
      text = ''
        # exit 78 (EX_CONFIG) on missing content: no restart loop until it is uploaded
        src=${lib.escapeShellArg inst.contentDir}
        track=${lib.escapeShellArg inst.track}
        cd ${stateDir name}

        for s in ${secret name "password"} ${secret name "admin-password"}; do
          [ -r "$s" ] || { echo "missing secret: $s" >&2; exit 78; }
        done

        # managed files are overwritten; the server keeps its own caches in cfg/
        mkdir -p cfg/cm_content
        install -m 600 ${f.serverCfg} cfg/server_cfg.ini
        replace-secret @PASSWORD@ ${secret name "password"} cfg/server_cfg.ini
        replace-secret @ADMIN_PASSWORD@ ${secret name "admin-password"} cfg/server_cfg.ini
        install -m 644 ${f.entryList} cfg/entry_list.ini
        install -m 644 ${f.extraCfg} cfg/extra_cfg.yml
        install -m 644 ${f.cspExtraOptions} cfg/csp_extra_options.ini
        install -m 644 ${f.wrapperParams} cfg/cm_wrapper_params.json
        install -m 644 ${f.content} cfg/cm_content/content.json

        # content symlink farm, only what the entry list needs
        rm -rf content
        mkdir -p content/cars content/tracks
        for car in ${lib.escapeShellArgs f.cars}; do
          [ -d "$src/cars/$car" ] || { echo "missing car: $src/cars/$car" >&2; exit 78; }
          ln -s "$src/cars/$car" "content/cars/$car"
        done
        [ -d "$src/tracks/$track" ] || { echo "missing track: $src/tracks/$track" >&2; exit 78; }
        ${
          if inst.trafficSpline == null
          then ''ln -s "$src/tracks/$track" "content/tracks/$track"''
          else ''
            # mirror the track down to the ai folder so only the server sees the spline
            [ -f ${lib.escapeShellArg inst.trafficSpline} ] || { echo "missing spline: ${inst.trafficSpline}" >&2; exit 78; }
            mirror() {
              mkdir -p "$2"
              for entry in "$1"/*; do
                [ "$(basename "$entry")" = "$3" ] || ln -s "$entry" "$2/"
              done
            }
            mirror "$src/tracks/$track" "content/tracks/$track" ${lib.escapeShellArg (
              if inst.trackLayout == ""
              then "ai"
              else inst.trackLayout
            )}
            ${lib.optionalString (aiParent != "") ''mirror "$src/tracks/$track${aiParent}" "content/tracks/$track${aiParent}" ai''}
            mkdir -p "content/tracks/$track${aiParent}/ai"
            ln -s ${lib.escapeShellArg inst.trafficSpline} "content/tracks/$track${aiParent}/ai/fast_lane.aip"
          ''
        }

        # CM direct-download archives, rebuilt when the source changes
        pack() { # <zip> <parent dir> <folder>
          local out="$PWD/$1"
          if [ -f "$out" ] && [ -z "$(find -L "$2/$3" -newer "$out" -print -quit)" ]; then
            return
          fi
          echo "packing $3"
          rm -f "$out.tmp"
          (cd "$2" && zip -qr -6 "$out.tmp" "$3")
          mv "$out.tmp" "$out"
        }
        mkdir -p ${f.downloads}/cars
        for car in ${lib.escapeShellArgs f.cars}; do
          pack "${f.downloads}/cars/$car.zip" "$src/cars" "$car"
        done
        pack "${f.downloads}/track.zip" "$src/tracks" "$track"
      '';
    };
in {
  options.homelab.assetto-server = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.assetto-server;
    };

    contentOwner = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User that uploads content; owns the content and spline directories";
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule instanceModule);
      default = {};
      description = "AssettoServer instances";
    };
  };

  config = lib.mkIf (enabled != {}) {
    assertions = let
      ports = lib.concatLists (lib.mapAttrsToList (_: i: [i.port i.httpPort]) enabled);
    in
      [
        {
          assertion = lib.allUnique ports;
          message = "homelab.assetto-server: instances must use distinct ports";
        }
      ]
      ++ lib.concatLists (lib.mapAttrsToList (name: inst: let
          count = cars: lib.foldl' (a: b: a + b) 0 (lib.attrValues cars);
        in [
          {
            assertion = inst.playerSlotOffset <= count inst.trafficCars;
            message = "assetto-server ${name}: playerSlotOffset requires enough traffic entries to fill preceding slots";
          }
          {
            assertion = inst.pitBoxes == null || count inst.playerCars + count inst.trafficCars <= inst.pitBoxes;
            message = "assetto-server ${name}: player and traffic entries exceed layout pit capacity";
          }
        ])
        enabled);

    users.users.assetto-server = {
      isSystemUser = true;
      group = "assetto-server";
    };
    users.groups.assetto-server = {};

    persist.dirs = ["/var/lib/assetto-server"];

    # content layout; the files themselves are uploaded by contentOwner
    systemd.tmpfiles.rules = let
      owner = cfg.contentOwner;
      group = config.users.users.${owner}.group;
      dir = path: "d ${path} 0755 ${owner} ${group} - -";
    in
      lib.unique (lib.concatLists (lib.mapAttrsToList (_: i:
        map dir ([i.contentDir "${i.contentDir}/cars" "${i.contentDir}/tracks"]
          ++ lib.optional (i.trafficSpline != null) (dirOf i.trafficSpline)))
      enabled));

    sops.secrets = lib.mkMerge (lib.mapAttrsToList (name: _: {
        "assetto-server/${name}/password".owner = "assetto-server";
        "assetto-server/${name}/admin-password".owner = "assetto-server";
      })
      enabled);

    homelab.firewall.extraInputRules = lib.concatStrings (lib.mapAttrsToList (_: i:
      lib.concatMapStrings (iface: ''
        iifname "${iface}" tcp dport { ${toString i.port}, ${toString i.httpPort} } accept
        iifname "${iface}" udp dport ${toString i.port} accept
      '')
      i.allowedInterfaces)
    enabled);

    homelab.tcpForwards = lib.mkMerge (lib.mapAttrsToList (name: i:
      lib.mkIf i.public {
        "assetto-${name}-tcp" = {
          listen = i.port;
          inherit (i) port;
        };
        "assetto-${name}-udp" = {
          listen = i.port;
          inherit (i) port;
          proto = "udp";
        };
        "assetto-${name}-http" = {
          listen = i.httpPort;
          port = i.httpPort;
        };
      })
    enabled);

    systemd.services = lib.mapAttrs' (name: inst:
      lib.nameValuePair "assetto-server-${name}" {
        description = "Assetto Corsa server (${name})";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];

        serviceConfig = {
          User = "assetto-server";
          Group = "assetto-server";
          StateDirectory = "assetto-server/${name}";
          WorkingDirectory = stateDir name;
          ExecStartPre = lib.getExe (mkPrepare name inst);
          ExecStart = lib.getExe cfg.package;
          # first start zips the track and cars
          TimeoutStartSec = "30min";
          Restart = "on-failure";
          RestartSec = 10;
          RestartPreventExitStatus = 78;

          ReadOnlyPaths = [inst.contentDir] ++ lib.optional (inst.trafficSpline != null) inst.trafficSpline;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
        };
      })
    enabled;
  };
}
