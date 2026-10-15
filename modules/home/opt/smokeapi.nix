# based on https://github.com/ryndubei/nixos-user
#
# TODO: remove redundant bs
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.smokeapi;

  smokeapi = pkgs.fetchzip {
    url = "https://github.com/acidicoala/SmokeAPI/releases/download/v2.0.5/SmokeAPI-v2.0.5.zip";
    hash = "sha256-urOLmQ2xY4NKxyCznVUOMNAMSY7btLhKbca/FMHNHNQ=";
    stripRoot = false;
  };

  # v4 adds linux builds (proxy mode: replaces libsteam_api.so). windows dlls stay on v2
  smokeapi-linux-src = pkgs.fetchzip {
    url = "https://github.com/acidicoala/SmokeAPI/releases/download/v4.1.3/SmokeAPI-v4.1.3.zip";
    hash = "sha256-c5UwDX6o2OsMFd+f95tlTMNwCbIrgM+C8BLPfInUo1Y=";
    stripRoot = false;
  };

  # the steam runtime's libnghttp2 is too old for smokeapi (missing symbols, so the
  # game silently falls back to the original lib). point it at nixpkgs' instead,
  # /nix/store is visible inside pressure-vessel
  smokeapi-linux = pkgs.runCommand "smokeapi-linux" {nativeBuildInputs = [pkgs.patchelf];} ''
    mkdir -p $out
    install -m 755 ${smokeapi-linux-src}/libsmoke_api64.so ${smokeapi-linux-src}/libsmoke_api32.so $out/
    patchelf --replace-needed libnghttp2.so.14 ${pkgs.nghttp2.lib}/lib/libnghttp2.so.14 $out/libsmoke_api64.so
    patchelf --replace-needed libnghttp2.so.14 ${pkgs.pkgsi686Linux.nghttp2.lib}/lib/libnghttp2.so.14 $out/libsmoke_api32.so
  '';

  apply-smokeapi = pkgs.writeShellScriptBin "apply-smokeapi" ''
    set -euo pipefail

    # Steam library paths (native Steam installation)
    STEAM_ROOT="$HOME/.local/share/Steam"
    LIBRARYFOLDERS="$STEAM_ROOT/steamapps/libraryfolders.vdf"

    if [ ! -f "$LIBRARYFOLDERS" ]; then
      echo "Steam libraryfolders.vdf not found at $LIBRARYFOLDERS" >&2
      exit 1
    fi

    # Find library paths from libraryfolders.vdf
    # Extract paths using simple grep and cut
    LIBRARY_PATHS=$(grep '"path"' "$LIBRARYFOLDERS" | grep -o '"[^"]*"$' | tr -d '"' || echo "$STEAM_ROOT")

    # Add any additional custom library paths
    ${lib.concatMapStringsSep "\n" (path: ''LIBRARY_PATHS="$LIBRARY_PATHS ${path}"'') cfg.additionalLibraryPaths}

    # Function to patch DLLs in a directory
    patch_directory() {
      local dir="$1"
      local label="$2"
      echo "Searching $label: $dir"

      if [ ! -d "$dir" ]; then
        echo "  Directory does not exist, skipping"
        return
      fi

      local found_any=false

      # Backup and replace 32-bit DLL
      while IFS= read -r -d "" dll; do
        found_any=true
        echo "  Found 32-bit DLL: $dll"
        if [ ! -f "$(dirname "$dll")/steam_api_o.dll" ]; then
          cp "$dll" "$(dirname "$dll")/steam_api_o.dll"
          echo "    ✓ Backed up original"
        else
          echo "    ℹ Already backed up"
        fi
        cp "${smokeapi}/steam_api.dll" "$dll"
        echo "    ✓ Applied SmokeAPI patch"
      done < <(find "$dir" -type f -name "steam_api.dll" -print0)

      # Backup and replace 64-bit DLL
      while IFS= read -r -d "" dll; do
        found_any=true
        echo "  Found 64-bit DLL: $dll"
        if [ ! -f "$(dirname "$dll")/steam_api64_o.dll" ]; then
          cp "$dll" "$(dirname "$dll")/steam_api64_o.dll"
          echo "    ✓ Backed up original"
        else
          echo "    ℹ Already backed up"
        fi
        cp "${smokeapi}/steam_api64.dll" "$dll"
        echo "    ✓ Applied SmokeAPI patch"
      done < <(find "$dir" -type f -name "steam_api64.dll" -print0)

      # Backup and replace native linux libs. install(1) unlinks first, so a
      # running game keeps its mapped copy instead of crashing
      while IFS= read -r -d "" so; do
        found_any=true
        local bits smoke
        bits=$(od -An -tx1 -j4 -N1 "$so" | tr -d ' ')
        if [ "$bits" = "02" ]; then smoke="${smokeapi-linux}/libsmoke_api64.so"; else smoke="${smokeapi-linux}/libsmoke_api32.so"; fi
        echo "  Found linux lib: $so"
        if cmp -s "$so" "$smoke"; then
          echo "    ℹ Already patched"
          continue
        fi
        # only back up the real steam lib, never an older smokeapi build
        if grep -qa libsmoke_api "$so"; then
          echo "    ℹ Replacing older SmokeAPI build"
        else
          install -m 755 "$so" "$(dirname "$so")/libsteam_api_o.so"
          echo "    ✓ Backed up original"
        fi
        install -m 755 "$smoke" "$so"
        echo "    ✓ Applied SmokeAPI patch"
      done < <(find "$dir" -type f -name "libsteam_api.so" -print0)

      if [ "$found_any" = false ]; then
        echo "  ⚠ No Steam API DLLs found in this directory"
      fi
    }

    apply_app() {
    local app_id="$1"
    echo ""
    echo "##### Applying SmokeAPI to app ID $app_id #####"

    # Track if we found anything
    local found_game=false

    # Search in each library path
    for library in $LIBRARY_PATHS; do
      echo ""
      echo "=== Checking library: $library ==="

      # Check compatdata (Proton prefix)
      compatdata_path="$library/steamapps/compatdata/$app_id"
      if [ -d "$compatdata_path" ]; then
        echo "✓ Found compatdata for app $app_id"
        patch_directory "$compatdata_path" "compatdata (Proton prefix)"
        found_game=true
      else
        echo "✗ No compatdata found at $compatdata_path"
      fi

      # Check common (game installation directory)
      manifest="$library/steamapps/appmanifest_$app_id.acf"
      if [ -f "$manifest" ]; then
        echo "✓ Found manifest: $manifest"
        # Extract installdir value using grep and cut (handles tabs)
        game_dir=$(grep '"installdir"' "$manifest" | grep -o '"[^"]*"$' | tr -d '"' || echo "")
        if [ -n "$game_dir" ]; then
          game_path="$library/steamapps/common/$game_dir"
          echo "✓ Game install directory: $game_path"
          patch_directory "$game_path" "game install directory"
          found_game=true
        else
          echo "✗ Could not parse installdir from manifest"
        fi
      else
        echo "✗ No manifest found at $manifest"
      fi
    done

    echo ""
    if [ "$found_game" = false ]; then
      echo "⚠ Warning: No game installation found for app ID $app_id"
      echo "Make sure the game is installed and the library paths are correct."
      return 1
    fi
    }

    failed=0
    for app_id in ${lib.concatMapStringsSep " " toString cfg.appIds}; do
      apply_app "$app_id" || failed=1
    done

    echo ""
    echo "SmokeAPI application complete!"
    exit "$failed"
  '';
in {
  options.modules.smokeapi = {
    enable = lib.mkEnableOption "SmokeAPI DLC unlocker";

    appIds = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = "Steam app IDs to apply SmokeAPI to";
      example = [2161700];
    };

    additionalLibraryPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional Steam library paths to search (e.g., /games/SteamLibrary)";
      example = ["/games/SteamLibrary"];
    };

    autoApply = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically apply SmokeAPI on login and home-manager activation";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [apply-smokeapi];

    # Systemd service to apply on login
    systemd.user.services.apply-smokeapi = lib.mkIf cfg.autoApply {
      Unit = {
        Description = "Apply SmokeAPI DLC unlocker";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${apply-smokeapi}/bin/apply-smokeapi";
        # Don't fail if Steam isn't installed yet
        RemainAfterExit = false;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    # Also run on home-manager activation
    home.activation.applySmokeapi = lib.mkIf cfg.autoApply (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        if command -v systemctl &> /dev/null; then
          run ${pkgs.systemd}/bin/systemctl --user start apply-smokeapi.service || true
        fi
      ''
    );
  };
}
