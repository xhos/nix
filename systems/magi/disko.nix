# optiplex 5040s boot off a 256G m.2 nvme
{disk ? "/dev/nvme0n1", ...}: {
  disko.devices = {
    disk.system = {
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
          nix = {
            size = "50G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = ["noatime"];
            };
          };
          persist = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };

    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = ["size=25%" "mode=755"];
    };
  };
}
