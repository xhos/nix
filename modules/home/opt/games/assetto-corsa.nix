# Assetto Corsa + Content Manager under Proton-GE 9-20. Runtime state is mutable
# (lives on the games disk); only the launcher and source archives are Nix-built.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.games.asseta;

  proton = pkgs.proton-ge-9-20.steamcompattool;

  cm = pkgs.fetchurl {
    name = "content-manager-0.8.2782.39874.zip";
    url = "https://github.com/gro-ove/actools/releases/download/v0.8.2782.39874/Content.Manager.zip";
    sha256 = "67998c57fc520946f4041152dc3a1f3d5558d4da8062630e9079e31061a21f68";
  };
  fonts = pkgs.fetchurl {
    name = "content-manager-fonts.zip";
    url = "https://files.acstuff.ru/shared/T0Zj/fonts.zip";
    sha256 = "c18efdf0ce4a36d9cecbd4f97b7f4b608bd2b6eca999b46ec2b4d93fb2de49b2";
  };
  csp = pkgs.fetchurl {
    name = "lights-patch-v0.2.11.zip";
    url = "https://acstuff.club/patch/?get=0.2.11";
    sha256 = "0729ccaebb403a7a6d1c40516990da8116cb5f56eea4c1fe0bdd29863a5a6ffb";
  };

  # seeded into CM's settings on first setup only
  cmDefaults = pkgs.writeText "Values.data" (lib.concatStringsSep "\n" [
    "version: 2"
    "_ac_root\tD:\\\\"
    "Settings.CommonSettings.UpdatePeriod\t00:00:00"
    "Settings.CommonSettings.UpdateToNontestedVersions\tFalse"
    "Settings.CommonSettings.LaunchSteamAtStart\tFalse"
    "Settings.IntegratedSettings.DiscordIntegration\tFalse"
    "Settings.IntegratedSettings.SteamIntegration\tFalse"
    ""
  ]);

  assetto-corsa-env = pkgs.writeShellApplication {
    name = "assetto-corsa-env";
    runtimeInputs = with pkgs; [coreutils gnugrep util-linux unzip steam steam-run];
    text = ''
      export AC_GAME_DIR=${cfg.gameDir}
      export AC_STATE_DIR=${cfg.stateDir}
      export AC_PROTON=${proton}
      export AC_CM_ARCHIVE=${cm}
      export AC_FONTS_ARCHIVE=${fonts}
      export AC_CSP_ARCHIVE=${csp}
      export AC_CM_DEFAULTS=${cmDefaults}
      export AC_PROTONTRICKS=${pkgs.protontricks.override {extraCompatPaths = "${proton}";}}/bin/protontricks
      # State lives on the persistent games disk.
      game="''${AC_GAME_DIR:-/games/SteamLibrary/steamapps/common/assettocorsa}"
      state="''${AC_STATE_DIR:-/games/assetto-corsa}"
      prefix="$state/compatdata/pfx"
      cm_settings="$prefix/drive_c/users/steamuser/AppData/Local/AcTools Content Manager"
      # /tmp and the default home cache are volatile on vyverne. Keep installer
      # downloads and extraction work on the persistent games disk, outside tmpfs.
      export WINETRICKS_CACHE="$state/cache/winetricks"
      export XDG_CACHE_HOME="$state/cache"
      export TMPDIR="$state/tmp"
      export STEAM_COMPAT_CLIENT_INSTALL_PATH="''${STEAM_DIR:-$HOME/.local/share/Steam}"
      export STEAM_DIR="$STEAM_COMPAT_CLIENT_INSTALL_PATH"
      export STEAM_COMPAT_DATA_PATH="$state/compatdata"
      export STEAM_COMPAT_INSTALL_PATH="$game"
      export STEAM_COMPAT_SHADER_PATH="$state/shadercache"
      # Steam exposes the prefix and game automatically, but not their sibling files.
      export STEAM_COMPAT_MOUNTS="$state:$game''${STEAM_COMPAT_MOUNTS:+:$STEAM_COMPAT_MOUNTS}"
      export SteamAppId=244210 SteamGameId=244210 STEAM_COMPAT_APP_ID=244210
      export PROTON_VERSION=GE-Proton9-20
      export PULSE_LATENCY_MSEC=60
      export WINEDLLOVERRIDES="dwrite=n,b;winemenubuilder.exe=d"
      runtime="$STEAM_DIR/steamapps/common/SteamLinuxRuntime_sniper/_v2-entry-point"
      cm="$state/Content Manager Safe.exe"

      fail() { printf '%s\n' "$*" >&2; exit 1; }
      require_setup() {
        [[ -f "$state/setup-complete" ]] || fail 'Run assetto-corsa-env setup first.'
        [[ -f "$runtime" ]] || fail 'Install Steam Linux Runtime 3.0 (sniper) through Steam.'
        [[ -f "$game/acs.exe" ]] || fail "Assetto Corsa not found at $game"
        [[ -f "$cm" && -f "$prefix/system.reg" ]] || fail 'CM or its prefix is missing; inspect the environment before running setup again.'
      }
      lock_session() {
        exec 8>"$state/session.lock"
        flock "$@" 8 || fail 'Close Content Manager, the game, and installers first.'
      }
      proton_run() {
        mkdir -p "$TMPDIR" "$WINETRICKS_CACHE"
        # Mutating maintenance takes an exclusive lock; launchers share it.
        lock_session -s
        # Steam's runtime supplies the libraries GE-Proton was built against.
        (cd "$game" || exit; steam-run "$runtime" --verb=run -- "$AC_PROTON/proton" run "$@")
      }
      case "''${1:-cm}" in
        setup)
          [[ -f "$game/acs.exe" ]] || fail "Assetto Corsa not found at $game"
          [[ -f "$runtime" ]] || fail 'Install Steam Linux Runtime 3.0 (sniper) through Steam.'
          mkdir -p "$state/compatdata" "$state/shadercache" "$TMPDIR" "$WINETRICKS_CACHE"
          exec 9>"$state/setup.lock"
          flock -n 9 || fail 'Another setup is already running.'
          if [[ -f "$state/setup-complete" ]]; then
            require_setup
            printf 'Already configured: %s\n' "$state"
            exit 0
          fi
          lock_session -n
          if [[ ! -f "$cm" ]]; then
            unzip -p "$AC_CM_ARCHIVE" 'Content Manager.exe' > "$cm.partial"
            mv "$cm.partial" "$cm"
          fi
          # waitforexitandrun applies GE's AC fixes (.NET, DirectX helpers, Windows 10).
          (cd "$game" || exit; steam-run "$runtime" --verb=waitforexitandrun -- \
            "$AC_PROTON/proton" waitforexitandrun wineboot.exe -u)
          [[ -f "$prefix/system.reg" ]] || fail 'Proton prefix initialization failed.'
          # Protonfixes can log an error and still launch wineboot. Verify its verbs.
          for verb in dotnet452 d3dx11_43 d3dcompiler_47 win10; do
            grep -qx "$verb" "$prefix/winetricks.log" || fail "Missing dependency: $verb; rerun setup after fixing the installer error."
          done
          # D: is stable for Windows guides and external mod installers.
          if [[ -e "$prefix/dosdevices/d:" || -L "$prefix/dosdevices/d:" ]]; then
            [[ "$(readlink -f "$prefix/dosdevices/d:")" == "$(readlink -f "$game")" ]] || fail 'D: is already mapped elsewhere.'
          else
            ln -s "$game" "$prefix/dosdevices/d:"
          fi
          mkdir -p "$prefix/drive_c/Program Files (x86)/Steam/config"
          ln -sfn "$STEAM_DIR/config/loginusers.vdf" \
            "$prefix/drive_c/Program Files (x86)/Steam/config/loginusers.vdf"
          mkdir -p "$cm_settings"
          if [[ ! -f "$cm_settings/Values.data" ]]; then
            cp "$AC_CM_DEFAULTS" "$cm_settings/Values.data"
            chmod u+w "$cm_settings/Values.data"
          fi
          "$AC_PROTONTRICKS" 244210 -q corefonts
          mkdir -p "$game/content/fonts"
          # Preserve any existing system fonts before installing the CM font bundle.
          if [[ -d "$game/content/fonts/system" && ! -e "$state/fonts-before-setup" ]]; then
            cp -a "$game/content/fonts/system" "$state/fonts-before-setup"
          fi
          unzip -o "$AC_FONTS_ARCHIVE" 'system/*' -d "$game/content/fonts"
          printf 'GE-Proton9-20\nCM 0.8.2782.39874\n' > "$state/setup-complete"
          printf 'Ready. Run assetto-corsa-env cm; choose D:\\ as the game directory.\n'
          ;;
        cm)
          require_setup
          shift "$(( $# > 0 ? 1 : 0 ))"
          # CM and the game need the native Steam client for Steam authentication.
          # Starting a new Steam client can stay in the foreground indefinitely.
          mkdir -p "$state/logs"
          env -u SteamAppId -u SteamGameId -u STEAM_COMPAT_APP_ID \
            -u STEAM_COMPAT_DATA_PATH steam -silent >> "$state/logs/steam.log" 2>&1 &
          proton_run "$cm" --software-rendering --disable-values-compression "$@"
          ;;
        run)
          require_setup
          shift
          [[ $# -gt 0 ]] || fail 'Usage: assetto-corsa-env run /path/to/installer.exe [arguments]'
          executable="$1"; shift
          [[ -f "$executable" ]] || fail "File not found: $executable"
          executable="$(realpath "$executable")"
          STEAM_COMPAT_MOUNTS="$(dirname "$executable"):$STEAM_COMPAT_MOUNTS"
          export STEAM_COMPAT_MOUNTS
          case "''${executable,,}" in
            *.msi) proton_run msiexec.exe /i "$executable" "$@" ;;
            *.bat|*.cmd) proton_run cmd.exe /c "$executable" "$@" ;;
            *) proton_run "$executable" "$@" ;;
          esac
          ;;
        explorer)
          require_setup
          proton_run explorer.exe "D:\\"
          ;;
        winetricks)
          require_setup
          shift
          lock_session -n
          exec "$AC_PROTONTRICKS" 244210 "$@"
          ;;
        install-csp)
          require_setup
          lock_session -n
          [[ ! -e "$game/dwrite.dll" && ! -e "$game/extension" ]] || \
            fail 'CSP already exists. Manage updates in CM; this command only installs a clean baseline.'
          unzip "$AC_CSP_ARCHIVE" -d "$game"
          printf 'Installed CSP 0.2.11. Keep this version until a replacement has been tested.\n'
          ;;
        status)
          printf 'Game: %s\nState: %s\nProton: %s\nWindows game path: D:\\\n' "$game" "$state" "$AC_PROTON"
          if [[ -f "$state/setup-complete" ]]; then cat "$state/setup-complete"; else printf 'Setup not completed.\n'; fi
          ;;
        help|-h|--help)
          printf '%s\n' 'Usage: assetto-corsa-env {setup|cm [URI]|run FILE [ARGS]|explorer|winetricks VERBS|install-csp|status}'
          ;;
        *) fail 'Unknown command. Run assetto-corsa-env --help.' ;;
      esac
    '';
    meta.description = "Pinned Assetto Corsa and Content Manager environment";
  };
in {
  options.games.asseta = {
    enable = lib.mkEnableOption "Assetto Corsa with Content Manager under Proton-GE";

    gameDir = lib.mkOption {
      type = lib.types.str;
      default = "/games/SteamLibrary/steamapps/common/assettocorsa";
      description = "Steam install directory of Assetto Corsa";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/games/assetto-corsa";
      description = "persistent directory for the prefix, caches, locks and CM";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [assetto-corsa-env];

    xdg.desktopEntries = {
      assetto-corsa-cm = {
        name = "Assetto Corsa Content Manager";
        exec = "${assetto-corsa-env}/bin/assetto-corsa-env cm %u";
        icon = "steam_icon_244210";
        categories = ["Game"];
        mimeType = ["x-scheme-handler/acmanager"];
        terminal = false;
      };

      assetto-corsa-installer = {
        name = "Run in Assetto Corsa";
        exec = "${assetto-corsa-env}/bin/assetto-corsa-env run %f";
        icon = "steam_icon_244210";
        categories = ["Game"];
        mimeType = ["application/x-ms-dos-executable" "application/vnd.microsoft.portable-executable"];
        noDisplay = true;
        terminal = false;
      };
    };

    xdg.mimeApps.defaultApplications."x-scheme-handler/acmanager" = ["assetto-corsa-cm.desktop"];

    wayland.windowManager.hyprland.extraLuaFiles."assetto-corsa" = {
      autoLoad = true;
      content = ''
        -- CM dropdowns share the shell's class/title. Tag only a verified
        -- explorer.exe /desktop process with the observed tiny window shape.
        local function hide_ac_shell(w)
          if w.class ~= "steam_app_244210" or w.title ~= "" or not w.floating then return end
          if w.size.x <= 0 or w.size.x > 200 or w.size.y <= 0 or w.size.y > 32 then return end
          local proc = "/proc/" .. tostring(w.pid)
          local f = io.open(proc .. "/comm", "r")
          if not f then return end
          local comm = f:read("*l")
          f:close()
          if comm ~= "explorer.exe" then return end
          f = io.open(proc .. "/cmdline", "r")
          if not f then return end
          local cmd = f:read("*a"):gsub("%z", " "):lower()
          f:close()
          if not cmd:match("/desktop%s*$") then return end
          hl.dispatch(hl.dsp.window.tag({ window = w, tag = "+ac-explorer-desktop" }))
        end

        hl.window_rule({
          name = "assetto-corsa-explorer-only",
          match = { tag = "ac-explorer-desktop" },
          opacity = "0.0 override 0.0 override 0.0 override",
          no_focus = true,
          no_anim = true,
          no_blur = true,
          no_shadow = true,
          decorate = false,
        })
        hl.on("window.open", hide_ac_shell)
        for _, w in ipairs(hl.get_windows()) do hide_ac_shell(w) end
      '';
    };
  };
}
