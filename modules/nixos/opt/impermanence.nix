{
  lib,
  config,
  ...
}: let
  persistIf = condition: persistConfig: lib.mkIf condition persistConfig;
in {
  options.impermanence.enable = lib.mkEnableOption "wipe root filesystem on reboot, persist selected directories";

  options.persist = {
    dirs = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [];
      description = "dirs to persist";
    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "files to persist";
    };
  };

  config = lib.mkIf config.impermanence.enable {
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;

    programs.fuse.userAllowOther = true;

    environment.persistence."/persist" = lib.mkMerge [
      {
        hideMounts = true;
        directories =
          [
            "/etc/ssh"
            "/var/lib/nixos"
            "/var/lib/systemd/"
            "/var/lib/upower"
            "/var/lib/fprint"
            "/var/lib/fail2ban/"
            "/var/log"
          ]
          ++ config.persist.dirs;
        files =
          [
            "/etc/machine-id"
          ]
          ++ config.persist.files;
      }

      (persistIf config.bluetooth.enable {
        directories = [
          "/var/lib/bluetooth"
        ];
      })

      (persistIf config.vm.enable {
        directories = [
          "/var/lib/libvirt"
          "/var/lib/docker"
        ];
      })

      (persistIf config.ai.enable {
        directories = [
          "/var/lib/private/ollama"
        ];
      })

      (persistIf config.games.enable {
        directories = ["/var/lib/zerotier-one"];
        # home paths must go through users.<name> so parent dirs (.local, .local/share)
        # are created owned by xhos, not root
        users.xhos.directories = [
          ".steam"
          ".local/share/Steam"
        ];
      })

      (persistIf (config.greeter == "regreet") {
        directories = [
          "/var/lib/regreet"
        ];
      })

      (persistIf config.headless {
        directories = [
          "/var/lib/postgresql"
          "/var/lib/wireguard" # wg proxy private key
          "/var/lib/docker"
          "/var/lib/acme"
          "/var/lib/caddy"
          "/var/lib/zipline"
          "/var/lib/AdGuardHome"
          "/var/lib/dnsmasq"
          "/var/lib/glance"
          "/var/lib/qBittorrent"
          "/var/lib/hass"
          "/var/lib/wakapi"
        ];
        # TODO: why here
        users.xhos.directories = [".local/share/syncthing"];
      })
    ];
  };
}
