{
  lib,
  config,
  ...
}: {
  options.homelab.glance.enable = lib.mkEnableOption "glance dashboard";

  config = lib.mkIf config.homelab.glance.enable {
    homelab.exposedServices.glance = {
      port = config.services.glance.settings.server.port;
      dashboard = {
        group = null;
        monitor = false;
      };
    };

    # unset dynamic user stuff which makes it difficult to persist
    systemd.services.glance.serviceConfig = {
      StateDirectory = lib.mkForce null;
      DynamicUser = lib.mkForce false;
      User = "glance";
      Group = "glance";
    };

    users.users.glance = {
      isSystemUser = true;
      group = "glance";
    };
    users.groups.glance = {};

    services.glance = {
      enable = true;
      openFirewall = true;

      settings = let
        domain = config.homelab.config.domain;

        services = lib.attrValues (lib.mapAttrs (name: svc:
          svc
          // {
            title =
              if svc.name != ""
              then svc.name
              else name;
            url = "https://${
              if svc.subdomain != ""
              then svc.subdomain
              else name
            }.${domain}";
            icon =
              if svc.dashboard.icon != ""
              then svc.dashboard.icon
              else "sh:${name}";
          })
        config.homelab.exposedServices);

        bookmarked = lib.filter (s: s.dashboard.group != null) services;
        groups = lib.unique (["media" "personal" "home"] ++ map (s: s.dashboard.group) bookmarked);

        bookmarks = lib.filter (g: g.links != []) (map (group: {
            title = group;
            links = map (s: {inherit (s) title url icon;}) (lib.filter (s: s.dashboard.group == group) bookmarked);
          })
          groups);

        monitored = map (s: {inherit (s) title url;}) (lib.filter (s: s.dashboard.monitor) services);
      in {
        pages = [
          {
            name = "Home";
            head-widgets = [
              {
                type = "markets";
                hide-header = true;
                markets = [
                  {
                    symbol = "SPY";
                    name = "S&P 500";
                  }
                  {
                    symbol = "BTC-USD";
                    name = "Bitcoin";
                  }
                  {
                    symbol = "NVDA";
                    name = "NVIDIA";
                  }
                  {
                    symbol = "AAPL";
                    name = "Apple";
                  }
                  {
                    symbol = "MSFT";
                    name = "Microsoft";
                  }
                ];
              }
            ];

            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "clock";
                    hide-header = true;
                    hour-format = "24h";
                    timezones = [
                      {
                        timezone = "Europe/Lisbon";
                        label = "lisbon";
                      }
                      {
                        timezone = "Europe/Berlin";
                        label = "berlin";
                      }
                      {
                        timezone = "Europe/Kiev";
                        label = "lviv";
                      }
                      {
                        timezone = "Europe/Moscow";
                        label = "moscow";
                      }
                      {
                        timezone = "Asia/Tokyo";
                        label = "tokyo";
                      }
                      {
                        timezone = "America/Los_Angeles";
                        label = "los angeles";
                      }
                    ];
                  }
                  {
                    type = "calendar";
                    hide-header = true;
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "hacker-news";
                    hide-header = true;
                    limit = 15;
                    collapse-after = 5;
                  }
                  {
                    type = "bookmarks";
                    hide-header = true;
                    groups = bookmarks;
                  }
                ];
              }
              {
                size = "small";
                widgets = [
                  {
                    type = "weather";
                    hide-header = true;
                    units = "metric";
                    hour-format = "24h";
                    location = "Toronto, Canada";
                  }
                  {
                    type = "custom-api";
                    title = "Air Quality";
                    hide-header = true;
                    cache = "10m";
                    url = "https://api.waqi.info/feed/geo:43.70011;-79.4163/?token=c1c138444a58023ceec2ac8ed53000041da15ffc";
                    template = ''
                      {{ $aqi := printf "%03s" (.JSON.String "data.aqi") }}
                      {{ $aqiraw := .JSON.String "data.aqi" }}
                      {{ $updated := .JSON.String "data.time.iso" }}
                      {{ $humidity := .JSON.String "data.iaqi.h.v" }}
                      {{ $ozone := .JSON.String "data.iaqi.o3.v" }}
                      {{ $pm25 := .JSON.String "data.iaqi.pm25.v" }}
                      {{ $pressure := .JSON.String "data.iaqi.p.v" }}

                      <div class="flex justify-between">
                        <div class="size-h5">
                          {{ if le $aqi "050" }}
                            <div class="color-positive">Good air quality</div>
                          {{ else if le $aqi "100" }}
                            <div class="color-primary">Moderate air quality</div>
                          {{ else }}
                            <div class="color-negative">Bad air quality</div>
                          {{ end }}
                        </div>
                      </div>

                      <div class="color-highlight size-h2">AQI: {{ $aqiraw }}</div>

                      <div class="margin-block-2">
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                        </div>

                      </div>
                    '';
                  }
                  {
                    type = "monitor";
                    style = "compact";
                    hide-header = true;
                    title = "service status";
                    sites = monitored;
                  }
                  {
                    type = "server-stats";
                    hide-header = true;
                    servers = [
                      {
                        type = "local";
                        name = "resources";
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];

        server = {
          host = "0.0.0.0";
          port = 3000;
        };

        branding = {
          hide-footer = true;
        };
      };
    };
  };
}
