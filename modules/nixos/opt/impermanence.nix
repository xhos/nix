{
  lib,
  config,
  ...
}: let
  persistIf = condition: persistConfig: lib.mkIf condition persistConfig;

  userDir = path: {
    directory = "/home/xhos/${path}";
    user = "xhos";
    group = "users";
    mode = "0755";
  };
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
    programs.fuse.userAllowOther = true;

    environment.persistence."/persist" = lib.mkMerge [
      {
        hideMounts = true;
        directories =
          [
            "/etc/nixos"
            "/etc/ssh"
            "/var/lib/nixos"
            "/var/lib/systemd/"
            "/etc/NetworkManager/system-connections"
            "/var/lib/fprint"
            "/var/lib/fail2ban/"
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
        directories = [
          (userDir ".steam")
          (userDir ".local/share/Steam")
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

          # TODO: why here
          "/home/xhos/.local/share/syncthing"

          # proxmox
          "/var/lib/pve-cluster"
          # "/var/lib/vz"
          "/var/lib/rrdcached"
          "/var/lib/pve-manager"
        ];
      })
    ];

    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=25%"
        "mode=755"
      ];
    };

    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;
  };
}
