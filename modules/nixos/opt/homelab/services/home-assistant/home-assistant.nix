{
  pkgs,
  config,
  lib,
  ...
}: {
  options.homelab.home-assistant.enable = lib.mkEnableOption "enable home assistant";

  config = lib.mkIf config.homelab.home-assistant.enable {
    sops.secrets."ssh/vyverne" = {
      mode = "0600";
      owner = "hass";
    };

    homelab.exposedServices.home-assistant = {
      port = 8123;
      name = "home assistant";
      dashboard.group = "home";
    };

    # mdns for homekit discovery
    homelab.firewall.extraInputRules = ''
      iifname ${config.homelab.baremetal.interface} ip saddr 10.0.0.0/24 udp dport 5353 accept
    '';

    services.home-assistant = let
      yandexBase = "yandex_station_xk0000000000000286720000e2296918";
      yandexStationId = "media_player.${yandexBase}";
      thermostat = "climate.thermostat";
      wakeTemp = 23;
    in {
      enable = true;
      extraComponents = [
        "wled"
        "rest"
        "upnp"
        "met"
        "homekit_controller"
        "google_translate"
        "mcp_server"
        "ollama"
        "ecobee"
      ];
      customComponents = [
        # 3.22.3 fixes login, yandex.ru/quasar was retired
        (pkgs.home-assistant-custom-components.yandex-station.overridePythonAttrs (old: rec {
          version = "3.22.3";
          src = pkgs.fetchFromGitHub {
            owner = "AlexxIT";
            repo = "YandexStation";
            tag = "v${version}";
            hash = "sha256-xQRgklLCE18GdMFBNDJjxoiqitBedCbAHhP/v7zD2DM=";
          };
          doCheck = false;
        }))
      ];
      lovelaceConfig = {
        title = "Home";
        views = [
          {
            title = "Home";
            path = "home";
            icon = "mdi:home";
            cards = [
              {
                type = "thermostat";
                entity = thermostat;
              }
              {
                type = "entities";
                title = "Quick controls";
                entities = [
                  {
                    entity = "switch.pc_power";
                    name = "PC";
                  }
                  {
                    entity = "light.wled";
                    name = "WLED";
                  }
                  {
                    entity = "switch.wled_album_sync";
                    name = "Album sync";
                  }
                ];
              }
              {
                type = "media-control";
                entity = yandexStationId;
              }
              {
                type = "weather-forecast";
                entity = "weather.forecast_home";
                forecast_type = "daily";
              }
              {
                type = "todo-list";
                entity = "todo.shopping_list";
              }
              {
                type = "entities";
                title = "Presence";
                entities = [
                  "person.mark"
                  "device_tracker.pixel_9_pro"
                  "sensor.pixel_9_pro_battery_level"
                  "sensor.pixel_9_pro_next_alarm"
                ];
              }
            ];
          }
          {
            title = "Climate";
            path = "climate";
            icon = "mdi:thermostat";
            cards = [
              {
                type = "thermostat";
                entity = thermostat;
              }
              {
                type = "entities";
                title = "Thermostat";
                entities = [
                  "sensor.thermostat_current_temperature"
                  "sensor.thermostat_current_humidity"
                  "select.thermostat_current_mode"
                  "select.thermostat_temperature_display_units"
                  "button.thermostat_clear_hold"
                  "button.thermostat_identify"
                  "sensor.wake_time"
                  "sensor.wake_preheat_start"
                ];
              }
              {
                type = "history-graph";
                title = "Last 24h";
                hours_to_show = 24;
                entities = [
                  "sensor.thermostat_current_temperature"
                  "sensor.thermostat_current_humidity"
                ];
              }
            ];
          }
          {
            title = "Lights";
            path = "lights";
            icon = "mdi:led-strip-variant";
            cards = [
              {
                type = "light";
                entity = "light.wled";
              }
              {
                type = "entities";
                title = "Effect";
                entities = [
                  "select.wled_preset"
                  "select.wled_playlist"
                  "select.wled_color_palette"
                  "number.wled_speed"
                  "number.wled_intensity"
                ];
              }
              {
                type = "entities";
                title = "Switches";
                entities = [
                  "switch.wled_album_sync"
                  "switch.wled_nightlight"
                  "switch.wled_sync_send"
                  "switch.wled_sync_receive"
                  "switch.wled_reverse"
                  "switch.bedroom_wled_freeze"
                  "select.wled_live_override"
                ];
              }
            ];
          }
          {
            title = "Media";
            path = "media";
            icon = "mdi:speaker";
            cards = [
              {
                type = "media-control";
                entity = yandexStationId;
              }
              {
                type = "entities";
                title = "Station";
                entities = [
                  "select.${yandexBase}_equalizer"
                  "conversation.yandex_station_max_alisa"
                  "tts.google_translate_en_com"
                ];
              }
              {
                type = "picture-entity";
                entity = "camera.${yandexBase}_lyrics";
                camera_view = "auto";
                show_name = false;
                show_state = false;
              }
              {
                type = "calendar";
                title = "Alarms";
                entities = ["calendar.${yandexBase}_calendar"];
              }
            ];
          }
          {
            title = "Phone";
            path = "phone";
            icon = "mdi:cellphone";
            cards = [
              {
                type = "map";
                hours_to_show = 24;
                entities = [
                  "person.mark"
                  "device_tracker.pixel_9_pro"
                ];
              }
              {
                type = "entities";
                title = "Battery";
                entities = [
                  "sensor.pixel_9_pro_battery_level"
                  "sensor.pixel_9_pro_battery_state"
                  "binary_sensor.pixel_9_pro_is_charging"
                  "sensor.pixel_9_pro_charger_type"
                  "sensor.pixel_9_pro_battery_health"
                  "sensor.pixel_9_pro_battery_temperature"
                  "sensor.pixel_9_pro_remaining_charge_time"
                ];
              }
              {
                type = "entities";
                title = "Network";
                entities = [
                  "sensor.pixel_9_pro_wi_fi_connection"
                  "sensor.pixel_9_pro_wi_fi_signal_strength"
                  "sensor.pixel_9_pro_network_type"
                  "sensor.pixel_9_pro_public_ip_address"
                  "binary_sensor.pixel_9_pro_hotspot_state"
                ];
              }
              {
                type = "entities";
                title = "State";
                entities = [
                  "sensor.pixel_9_pro_geocoded_location"
                  "sensor.pixel_9_pro_next_alarm"
                  "sensor.pixel_9_pro_last_used_app"
                  "binary_sensor.pixel_9_pro_device_locked"
                  "binary_sensor.pixel_9_pro_interactive"
                  "binary_sensor.pixel_9_pro_doze_mode"
                  "binary_sensor.pixel_9_pro_power_save"
                  "sensor.pixel_9_pro_ringer_mode"
                ];
              }
              {
                type = "entities";
                title = "Health";
                entities = [
                  "sensor.pixel_9_pro_daily_steps"
                  "sensor.pixel_9_pro_daily_distance"
                  "sensor.pixel_9_pro_sleep_duration"
                  "sensor.pixel_9_pro_heart_rate"
                  "sensor.pixel_9_pro_resting_heart_rate"
                  "sensor.pixel_9_pro_total_calories_burned"
                ];
              }
            ];
          }
          {
            title = "System";
            path = "system";
            icon = "mdi:server";
            cards = [
              {
                type = "entities";
                title = "Backups";
                entities = [
                  "sensor.backup_backup_manager_state"
                  "sensor.backup_next_scheduled_automatic_backup"
                  "sensor.backup_last_successful_automatic_backup"
                  "sensor.backup_last_attempted_automatic_backup"
                ];
              }
              {
                type = "entities";
                title = "WLED diagnostics";
                entities = [
                  "update.wled_firmware"
                  "sensor.wled_ip"
                  "sensor.wled_uptime"
                  "sensor.wled_free_memory"
                  "sensor.wled_led_count"
                  "sensor.wled_estimated_current"
                  "sensor.wled_max_current"
                  "sensor.wled_wi_fi_signal"
                  "sensor.wled_wi_fi_rssi"
                  "sensor.wled_wi_fi_channel"
                  "button.wled_restart"
                ];
              }
              {
                type = "entities";
                title = "Sun";
                entities = [
                  "sun.sun"
                  "sensor.sun_next_dawn"
                  "sensor.sun_next_rising"
                  "sensor.sun_next_noon"
                  "sensor.sun_next_setting"
                  "sensor.sun_next_dusk"
                  "sensor.sun_next_midnight"
                  "sensor.sun_solar_elevation"
                  "sensor.sun_solar_azimuth"
                ];
              }
            ];
          }
          {
            title = "All";
            path = "all";
            icon = "mdi:format-list-bulleted";
            strategy.type = "original-states";
          }
        ];
      };

      config = {
        default_config = {};

        lovelace.dashboards.nixos-lovelace = {
          mode = "yaml";
          filename = "ui-lovelace.yaml";
          title = "Home";
          icon = "mdi:home-assistant";
          show_in_sidebar = true;
        };
        wake_on_lan = {};
        logger.logs."custom_components.yandex_station" = "debug";

        yandex_station = {
          devices = {
            "xk0000000000000286720000e2296918" = {
              host = "10.0.0.130";
              name = "Yandex Station Max";
            };
          };
        };

        shell_command = {
          shutdown_vyverne = "${pkgs.openssh}/bin/ssh -i ${
            config.sops.secrets."ssh/vyverne".path
          } -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 xhos@10.0.0.11 sudo shutdown -h now";
        };

        switch = [
          {
            platform = "rest";
            name = "WLED Album Sync";
            resource = "http://127.0.0.1:9123/state";
            state_resource = "http://127.0.0.1:9123/status";
            body_on = builtins.toJSON {enabled = true;};
            body_off = builtins.toJSON {enabled = false;};
            headers.Content-Type = "application/json";
            is_on_template = "{{ value_json.enabled }}";
            icon = "mdi:album";
          }
          {
            platform = "wake_on_lan";
            mac = "c8:fe:0f:d0:3c:68";
            broadcast_address = "10.0.0.255";
            name = "PC Power";
            host = "10.0.0.11";
            turn_off = {
              service = "shell_command.shutdown_vyverne";
            };
          }
        ];

        template = [
          {
            sensor = [
              {
                # phone alarm if it's between 3am and noon on the upcoming morning, else 9am
                name = "Wake time";
                device_class = "timestamp";
                state = ''
                  {% set fallback = today_at('09:00') + timedelta(days=0 if now().hour < 12 else 1) %}
                  {% set a = states('sensor.pixel_9_pro_next_alarm') | as_datetime(none) %}
                  {% set a = a | as_local if a is not none else none %}
                  {% if a is not none and a.date() == fallback.date() and 3 <= a.hour < 12 %}
                    {{ a.isoformat() }}
                  {% else %}
                    {{ fallback.isoformat() }}
                  {% endif %}
                '';
              }
              {
                # ~20 min per °C to reach wakeTemp, from thermostat history
                name = "Wake preheat start";
                device_class = "timestamp";
                availability = "{{ states('sensor.wake_time') | as_datetime(none) is not none }}";
                state = ''
                  {% set cur = states('sensor.thermostat_current_temperature') | float(19) %}
                  {% set mins = ([${toString wakeTemp} - cur, 0] | max) * 20 + 10 %}
                  {{ (states('sensor.wake_time') | as_datetime - timedelta(minutes=mins)).isoformat() }}
                '';
              }
            ];
          }
        ];

        automation = [
          {
            alias = "Thermostat - Wake preheat";
            trigger = [
              {
                platform = "time";
                at = "sensor.wake_preheat_start";
              }
            ];
            action = [
              {variables.wake = "{{ states('sensor.wake_time') }}";}
              {
                service = "climate.set_temperature";
                target.entity_id = thermostat;
                data = {
                  hvac_mode = "heat";
                  temperature = wakeTemp;
                };
              }
              {wait_template = "{{ now() >= (wake | as_datetime) + timedelta(hours=1) }}";}
              {
                service = "climate.set_temperature";
                target.entity_id = thermostat;
                data = {
                  hvac_mode = "heat_cool";
                  # thermostat enforces a 3°C heat/cool gap
                  target_temp_low = 19;
                  target_temp_high = 22;
                };
              }
            ];
            mode = "single";
          }
          {
            alias = "Thermostat - Evening";
            trigger = [
              {
                platform = "time";
                at = "21:00:00";
              }
            ];
            action = [
              {
                service = "climate.set_temperature";
                target.entity_id = thermostat;
                data = {
                  hvac_mode = "heat_cool";
                  target_temp_low = 17;
                  target_temp_high = 20;
                };
              }
            ];
            mode = "single";
          }
          {
            alias = "Yandex - Turn On Computer";
            trigger = [
              {
                platform = "event";
                event_type = "yandex_speaker";
                event_data = {
                  value = "ничего не делай";
                  entity_id = yandexStationId;
                };
              }
            ];
            action = [
              {
                service = "switch.turn_on";
                target.entity_id = "switch.pc_power";
              }
              {
                service = "media_player.play_media";
                target.entity_id = yandexStationId;
                data = {
                  media_content_type = "text";
                  media_content_id = "Включаю компьютер";
                };
              }
            ];
            mode = "single";
          }
          {
            alias = "Yandex - Turn Off Computer";
            trigger = [
              {
                platform = "event";
                event_type = "yandex_speaker";
                event_data = {
                  value = "ничего не делай!";
                  entity_id = yandexStationId;
                };
              }
            ];
            action = [
              {
                service = "switch.turn_off";
                target.entity_id = "switch.pc_power";
              }
              {
                service = "media_player.play_media";
                target.entity_id = yandexStationId;
                data = {
                  media_content_type = "text";
                  media_content_id = "Выключаю компьютер";
                };
              }
            ];
            mode = "single";
          }
          {
            alias = "Yandex - Toggle WLED";
            trigger = [
              {
                platform = "event";
                event_type = "yandex_speaker";
                event_data = {
                  value = "ничего не делай!!";
                  entity_id = yandexStationId;
                };
              }
            ];
            action = [
              {
                service = "light.toggle";
                target.entity_id = "light.wled";
              }
            ];
            mode = "single";
          }
          {
            alias = "Yandex - Toggle WLED Sync";
            trigger = [
              {
                platform = "event";
                event_type = "yandex_speaker";
                event_data = {
                  value = "ничего не делай!!!!";
                  entity_id = yandexStationId;
                };
              }
            ];
            action = [
              {
                service = "switch.toggle";
                target.entity_id = "switch.wled_album_sync";
              }
              {
                service = "media_player.play_media";
                target.entity_id = yandexStationId;
                data = {
                  media_content_type = "text";
                  media_content_id = "переключаю синхронизацию";
                };
              }
            ];
            mode = "single";
          }
          # {
          #   alias = "Yandex - Auto Sync Shopping List";
          #   trigger = [
          #     {
          #       platform = "time";
          #       at = ["15:00:00"];
          #     }
          #   ];
          #   action = [
          #     {
          #       variables = {
          #         volume = "{{ state_attr('${yandexStationId}', 'volume_level') }}";
          #       };
          #     }
          #     {
          #       service = "media_player.volume_set";
          #       target.entity_id = yandexStationId;
          #       data = {
          #         volume_level = 0;
          #       };
          #     }
          #     {
          #       service = "media_player.play_media";
          #       target.entity_id = yandexStationId;
          #       data = {
          #         media_content_id = "update";
          #         media_content_type = "shopping_list";
          #       };
          #     }
          #     {
          #       wait_for_trigger = [
          #         {
          #           platform = "state";
          #           entity_id = yandexStationId;
          #           attribute = "alice_state";
          #           to = "IDLE";
          #         }
          #       ];
          #       timeout = "00:01:00";
          #       continue_on_timeout = true;
          #     }
          #     {
          #       service = "media_player.volume_set";
          #       target.entity_id = yandexStationId;
          #       data = {
          #         volume_level = "{{ volume }}";
          #       };
          #     }
          #   ];
          #   mode = "single";
          # }
          {
            alias = "Yandex - Manual Sync Shopping List";
            trigger = [
              {
                platform = "event";
                event_type = "yandex_speaker";
                event_data = {
                  value = "ничего не делай!!!";
                  entity_id = yandexStationId;
                };
              }
            ];
            action = [
              {
                service = "media_player.play_media";
                target.entity_id = yandexStationId;
                data = {
                  media_content_id = "update";
                  media_content_type = "shopping_list";
                };
              }
            ];
            mode = "single";
          }
        ];
      };
    };
  };
}
