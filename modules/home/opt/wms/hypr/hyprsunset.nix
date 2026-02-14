{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.wm == "hyprland") {
    services.wlsunset = {
      enable = true;

      latitude = "43.6534817";
      longitude = "-79.3839347";

      systemdTarget = "hyprland-session.target";
    };

    home.packages = with pkgs; [
      wl-clipboard
      curl
      jq

      (writeShellScriptBin "get-city-coords" ''
        #!/usr/bin/env bash

        if [ $# -eq 0 ]; then
          echo "usage: get-city-coords <city-name>"
          echo "example: get-city-coords \"tokyo\""
          exit 1
        fi

        CITY="$*"
        echo "looking up coords for: $CITY"

        RESPONSE=$(curl -s "https://nominatim.openstreetmap.org/search?q=$CITY&format=json&limit=1")

        if [ -z "$RESPONSE" ] || [ "$RESPONSE" = "[]" ]; then
          echo "err: city not found. try being more specific"
          exit 1
        fi

        LAT=$(echo "$RESPONSE" | jq -r '.[0].lat')
        LON=$(echo "$RESPONSE" | jq -r '.[0].lon')
        DISPLAY_NAME=$(echo "$RESPONSE" | jq -r '.[0].display_name')

        if [ "$LAT" = "null" ] || [ "$LON" = "null" ]; then
          echo "err: could not parse coordinates"
          exit 1
        fi

        echo "found: $DISPLAY_NAME"
        echo "coordinates: $LAT, $LON"
        echo ""

        CONFIG_TEXT="latitude = \"$LAT\";
        longitude = \"$LON\";"

        echo "config:"
        echo "$CONFIG_TEXT"

        echo "$CONFIG_TEXT" | wl-copy

        echo ""
        echo "copied to clipboard"
      '')
    ];

    wayland.windowManager.hyprland.settings = {
      bind = [
        # wlsunset has 3 modes that cycle with SIGUSR1:
        # 1. forced high temperature (day mode - 6500K)
        # 2. forced low temperature  (night mode - 3400K)
        # 3. automatic calculation   (default behavior)
        "SUPER, F9, exec, pkill -USR1 wlsunset"
      ];
    };

    systemd.user.services.wlsunset-notify = {
      Unit = {
        Description = "notify on wlsunset changes";
        After = ["wlsunset.service"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.libnotify}/bin/notify-send 'blue light filter' 'wlsunset started'";
      };
    };
  };
}
