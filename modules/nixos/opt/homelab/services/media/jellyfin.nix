{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [inputs.jellarr.nixosModules.default];

  options.homelab.media.jellyfin.enable = lib.mkEnableOption "enable jellyfin";

  config = lib.mkIf config.homelab.media.jellyfin.enable {
    homelab.exposedServices.jellyfin = {
      exposed = true;
      port = 8096;
      dashboard.group = "media";
    };

    persist.dirs = [
      "/var/lib/jellyfin"
      "/var/cache/jellyfin"
    ];

    systemd.tmpfiles.rules = [
      "d /media/cache 0755 root root -"
      "d /media/cache/jellyfin 0755 jellyfin jellyfin -"
    ];

    services.jellyfin = {
      enable = true;
      cacheDir = "/media/cache/jellyfin";
    };

    sops.secrets."media/api/jellyfin" = lib.optionalAttrs config.services.declarr.enable {
      group = config.services.declarr.group;
      mode = "0440";
    };
    sops.templates.jellarr-env.content = ''
      JELLARR_API_KEY=${config.sops.placeholder."media/api/jellyfin"}
    '';

    services.jellarr = {
      enable = true;
      environmentFile = config.sops.templates.jellarr-env.path;
      config = {
        version = 1;
        base_url = "http://127.0.0.1:8096";
        # Required by Jellarr's runtime schema, even with no managed settings.
        system = {};
        # Match existing library names: Jellarr creates missing libraries only.
        library.virtualFolders = [
          {
            name = "Movies";
            collectionType = "movies";
            libraryOptions.pathInfos = [{path = "/media/movies";}];
          }
          {
            name = "Anime";
            collectionType = "tvshows";
            libraryOptions.pathInfos = [{path = "/media/anime";}];
          }
          {
            name = "TV Shows";
            collectionType = "tvshows";
            libraryOptions.pathInfos = [{path = "/media/tv";}];
          }
        ];
      };
    };

    # Apply on boot/rebuild as well as through Jellarr's daily timer.
    systemd.services.jellarr = {
      wantedBy = ["multi-user.target"];
      wants = ["jellyfin.service"];
      after = ["jellyfin.service"];
      unitConfig.RequiresMountsFor = ["/media"];
      # Jellarr 0.1.0 does not expose monitoring or scheduled-task options.
      postStart = let
        libraryMaintenance = pkgs.writeText "jellyfin-library-maintenance.py" ''
          import json
          import os
          import urllib.request

          base_url = ${builtins.toJSON config.services.jellarr.config.base_url}
          library_names = ${builtins.toJSON (map (folder: folder.name) config.services.jellarr.config.library.virtualFolders)}

          def api(path, body=None):
              request = urllib.request.Request(
                  base_url + path,
                  data=None if body is None else json.dumps(body).encode(),
                  headers={
                      "X-Emby-Token": os.environ["JELLARR_API_KEY"],
                      "Content-Type": "application/json",
                  },
              )
              with urllib.request.urlopen(request, timeout=30) as response:
                  data = response.read()
                  return json.loads(data) if data else None

          for library in api("/Library/VirtualFolders"):
              if library["Name"] not in library_names:
                  continue
              options = library["LibraryOptions"]
              if not options.get("EnableRealtimeMonitor"):
                  options["EnableRealtimeMonitor"] = True
                  api("/Library/VirtualFolders/LibraryOptions", {
                      "Id": library["ItemId"], "LibraryOptions": options,
                  })
                  print("Enabled real-time monitoring:", library["Name"], flush=True)

          task = next(t for t in api("/ScheduledTasks") if t["Key"] == "RefreshLibrary")
          triggers = task["Triggers"]
          day_ticks = 24 * 60 * 60 * 10_000_000
          # Preserve existing triggers, including any more frequent interval.
          if not any(t["Type"] == "IntervalTrigger" and
                     0 < (t.get("IntervalTicks") or 0) <= day_ticks for t in triggers):
              triggers.append({"Type": "IntervalTrigger", "IntervalTicks": day_ticks})
              api("/ScheduledTasks/" + task["Id"] + "/Triggers", triggers)
              print("Enabled daily fallback library scan", flush=True)
        '';
      in "${pkgs.python3}/bin/python3 ${libraryMaintenance}";
    };

    systemd.services.jellyfin.unitConfig.RequiresMountsFor = ["/media"];
    systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
    };

    users = {
      groups.media = {};
      users = {
        jellyfin.extraGroups = [
          "video"
          "media"
        ];
        xhos.extraGroups = ["media"];
      };
    };
  };
}
