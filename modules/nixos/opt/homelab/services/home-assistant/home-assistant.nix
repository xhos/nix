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
    in {
      enable = true;
      extraComponents = [
        "wled"
        "upnp"
        "met"
        "homekit_controller"
        "google_translate"
        "mcp_server"
        "ollama"
      ];
      customComponents = [
        (pkgs.home-assistant-custom-components.yandex-station.overridePythonAttrs (old: {
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
                  "binary_sensor.sun_solar_rising"
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
        shopping_list = {};

        http = {
          use_x_forwarded_for = true;
          trusted_proxies = ["10.0.0.10" "127.0.0.1"];
        };

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
          } -o StrictHostKeyChecking=no -p 22 xhos@10.0.0.11 sudo shutdown -h now";
          toggle_wled_sync = "${pkgs.curl}/bin/curl -X POST http://localhost:9123/toggle";
        };

        switch = [
          {
            platform = "wake_on_lan";
            mac = "c8:fe:0f:d0:3c:68";
            name = "PC Power";
            host = "10.0.0.11";
            turn_off = {
              service = "shell_command.shutdown_vyverne";
            };
          }
        ];

        automation = [
          {
            alias = "Thermostat - Schedule";
            trigger = [
              {
                platform = "time";
                at = "05:00:00";
                id = "morning";
              }
              {
                platform = "time";
                at = "07:00:00";
                id = "day";
              }
              {
                platform = "time";
                at = "21:00:00";
                id = "evening";
              }
            ];
            action = [
              {
                choose = [
                  {
                    conditions = [
                      {
                        condition = "trigger";
                        id = "morning";
                      }
                    ];
                    sequence = [
                      {
                        service = "climate.set_temperature";
                        target.entity_id = thermostat;
                        data = {
                          hvac_mode = "heat";
                          temperature = 23;
                        };
                      }
                    ];
                  }
                  {
                    conditions = [
                      {
                        condition = "trigger";
                        id = "day";
                      }
                    ];
                    sequence = [
                      {
                        service = "climate.set_temperature";
                        target.entity_id = thermostat;
                        data = {
                          hvac_mode = "heat_cool";
                          target_temp_low = 19;
                          target_temp_high = 21;
                        };
                      }
                    ];
                  }
                  {
                    conditions = [
                      {
                        condition = "trigger";
                        id = "evening";
                      }
                    ];
                    sequence = [
                      {
                        service = "climate.set_temperature";
                        target.entity_id = thermostat;
                        data = {
                          hvac_mode = "heat_cool";
                          target_temp_low = 17;
                          target_temp_high = 19;
                        };
                      }
                    ];
                  }
                ];
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
                service = "shell_command.toggle_wled_sync";
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
