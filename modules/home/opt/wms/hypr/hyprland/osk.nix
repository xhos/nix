{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with config.lib.stylix.colors;
    lib.mkIf (config.wm == "hyprland") [
      (pkgs.writeShellApplication {
        name = "toggle-osk";
        runtimeInputs = [pkgs.procps];
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          if pgrep -f "^wvkbd-mobintl" > /dev/null; then
            pkill -f "^wvkbd-mobintl"
          else
            exec wvkbd-mobintl \
              --fn Hack \
              -L 250 \
              -R ${toString config.wayland.windowManager.hyprland.settings.decoration.rounding} \
              --bg ${base00} \
              --fg ${base05} \
              --fg-sp ${base0D} \
              --alpha 50 &
          fi
        '';
      })
    ];
}
