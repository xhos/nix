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

    _enrai.exposedServices.home-assistant.port = 8123;

    services.home-assistant = {
      enable = true;
      extraComponents = [
        "wled"
        "upnp"
        "met"
        "google_translate"
      ];
      customComponents = [
        (pkgs.home-assistant-custom-components.yandex-station.overridePythonAttrs (old: {
          doCheck = false;
        }))
      ];
      config = let
        yandexStationId = "media_player.yandex_station_xk0000000000000286720000e2296918";
      in {
        default_config = {};
        wake_on_lan = {};
        shopping_list = {};

        http = {
          use_x_forwarded_for = true;
          trusted_proxies = ["10.0.0.10" "127.0.0.1"];
        };

        yandex_station = {
          devices = {
            "xk0000000000000286720000e2296918" = {
              host = "10.0.0.30";
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
