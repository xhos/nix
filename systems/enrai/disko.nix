{
  disk ? "/dev/sda", # SSD
  dataDisk ? "/dev/sdb", # HDD
  ...
}: {
  disko.devices = {
    disk = {
      # system 512GB SSD
      system = {
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
              size = "150G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
                mountOptions = ["noatime"];
              };
            };
            persist = {
              size = "100G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persist";
                mountOptions = ["noatime"];
              };
            };
            media = {
              size = "100%"; # rest of SSD (~250GB)
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/media";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };

      # storage 1TB HDD
      storage = {
        type = "disk";
        device = dataDisk;
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/storage";
                mountOptions = ["noatime"];
              };
            };
          };
        };
      };
    };
  };
}
