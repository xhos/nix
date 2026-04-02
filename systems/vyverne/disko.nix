{disk ? "/dev/vda", ...}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = disk;

      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };

          games = {
            size = "1T";
            type = "8300";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/games";
              mountOptions = ["defaults"];
            };
          };

          zpool = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        normalization = "formD";
        xattr = "sa";
        acltype = "posixacl";
        mountpoint = "none";
      };
      datasets = {
        "local/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
        "safe/state" = {
          type = "zfs_fs";
          mountpoint = "/persist";
        };
      };
    };
  };
}
