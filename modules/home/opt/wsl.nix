# glue between a NixOS-WSL guest and its windows host: .wslconfig, windows
# terminal theme, clipboard, url opening, and the few windows binaries we want
# on PATH (the full windows PATH is dropped via wsl.interop.includePath).
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  cfg = config.modules.wsl;
  win = cfg.windowsHome;
  c = config.lib.stylix.colors.withHashtag;

  winBin = name: path:
    pkgs.writeShellScriptBin name ''exec "${path}" "$@"'';

  # windows binaries worth keeping on PATH
  shims = [
    (winBin "explorer.exe" "/mnt/c/Windows/explorer.exe")
    (winBin "clip.exe" "/mnt/c/Windows/System32/clip.exe")
    (winBin "wsl.exe" "/mnt/c/Windows/System32/wsl.exe")
    (winBin "powershell.exe" "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe")
    (winBin "code" "${win}/AppData/Local/Programs/Microsoft VS Code/bin/code")
  ];

  # wslg's wayland socket isn't reliably reachable from the login session, so
  # talk to the windows clipboard directly. named like wl-clipboard so existing
  # aliases keep working; flags are accepted and ignored.
  wl-copy = pkgs.writeShellScriptBin "wl-copy" ''
    args=()
    for a in "$@"; do [[ $a == -* ]] || args+=("$a"); done
    # clip.exe reads the OEM codepage unless fed utf-16le
    if [ ''${#args[@]} -gt 0 ]; then printf '%s' "''${args[*]}"; else cat; fi \
      | ${pkgs.glibc.bin}/bin/iconv -f utf-8 -t utf-16le \
      | /mnt/c/Windows/System32/clip.exe
  '';

  wl-paste = pkgs.writeShellScriptBin "wl-paste" ''
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -NonInteractive -Command \
      '[Console]::OutputEncoding = [Text.Encoding]::UTF8; [Console]::Out.Write((Get-Clipboard -Raw))' \
      | ${pkgs.gnused}/bin/sed 's/\r$//'
  '';

  # open urls and files with the windows default handler
  wsl-open = pkgs.writeShellScriptBin "wsl-open" ''
    for target in "$@"; do
      if [ -e "$target" ]; then target=$(wslpath -w "$target"); fi
      /mnt/c/Windows/explorer.exe "$target" || true # explorer exits 1 on success
    done
  '';

  xdg-open = pkgs.writeShellScriptBin "xdg-open" ''exec ${wsl-open}/bin/wsl-open "$@"'';

  wslconfig = pkgs.writeText "wslconfig" (lib.generators.toINI {} {
    wsl2 = {
      memory = cfg.memory;
      # mirrored mode left the vm with no interfaces at all on this laptop
      # (likely the globalprotect/protonvpn adapters on the host), so stay on NAT
      dnsTunneling = true;
      autoProxy = true;
    };
    # sparseVhd is left out: wsl disabled it upstream over data corruption
    experimental.autoMemoryReclaim = "gradual";
  });

  # https://learn.microsoft.com/windows/terminal/json-fragment-extensions
  wtFragment = pkgs.writeText "wt-fragment.json" (builtins.toJSON {
    schemes = [
      {
        name = "Stylix";
        background = c.base00;
        foreground = c.base05;
        cursorColor = c.base05;
        selectionBackground = c.base02;
        black = c.base00;
        red = c.base08;
        green = c.base0B;
        yellow = c.base0A;
        blue = c.base0D;
        purple = c.base0E;
        cyan = c.base0C;
        white = c.base05;
        brightBlack = c.base03;
        brightRed = c.base08;
        brightGreen = c.base0B;
        brightYellow = c.base0A;
        brightBlue = c.base0D;
        brightPurple = c.base0E;
        brightCyan = c.base0C;
        brightWhite = c.base07;
      }
    ];
    profiles = [
      ({
          updates = cfg.terminalProfileGuid;
          colorScheme = "Stylix";
        }
        # stylix is off on headless hosts, so its fonts are just defaults there
        // lib.optionalAttrs config.stylix.enable {
          font = {
            face = config.stylix.fonts.monospace.name;
            size = config.stylix.fonts.sizes.terminal;
          };
        })
    ];
  });

  wtFragmentDir = "${win}/AppData/Local/Microsoft/Windows Terminal/Fragments/nix";
in {
  options.modules.wsl = with lib; {
    enable = mkOption {
      type = types.bool;
      default = osConfig.wsl.enable or false;
      description = "windows host integration for NixOS-WSL";
    };
    windowsHome = mkOption {
      type = types.str;
      example = "/mnt/c/Users/me";
      description = "the windows user profile dir, as seen from wsl";
    };
    memory = mkOption {
      type = types.str;
      default = "8GB";
      description = "VM memory limit written to .wslconfig";
    };
    terminalProfileGuid = mkOption {
      type = types.str;
      description = "guid of the distro's windows terminal profile (see settings.json)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = shims ++ [wl-copy wl-paste wsl-open xdg-open];

    home.sessionVariables = {
      BROWSER = "wsl-open";
      # autoProxy imports the windows (work) proxy as http_proxy; keep local
      # and tailnet traffic off it
      no_proxy = "localhost,127.0.0.1,::1,.ts.xhos.dev,100.64.0.0/10";
      NO_PROXY = "localhost,127.0.0.1,::1,.ts.xhos.dev,100.64.0.0/10";
    };

    # windows can't read nix store symlinks, so copy real files over, and only
    # when they differ (rewriting .wslconfig is harmless but noisy)
    home.activation.wslWindowsFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
      wslSync() {
        if ! ${pkgs.diffutils}/bin/cmp -s "$1" "$2"; then
          run mkdir -p "$(dirname "$2")"
          run cp --no-preserve=mode "$1" "$2"
          if [ -n "''${3:-}" ]; then echo "$3"; fi
        fi
        return 0
      }
      if [ -d "${win}" ]; then
        wslSync ${wslconfig} "${win}/.wslconfig" \
          "updated .wslconfig, run 'wsl.exe --shutdown' from windows to apply"
        wslSync ${wtFragment} "${wtFragmentDir}/${osConfig.networking.hostName}.json"
      else
        echo "modules.wsl: ${win} not found, skipping windows-side files" >&2
      fi
    '';
  };
}
