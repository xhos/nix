# my external drive
{
  disko.devices.disk.elements = {
    type = "disk";
    device = "/dev/disk/by-id/usb-WD_Elements_2621_575839324443354C59555255-0:0";
    content = {
      type = "gpt";
      partitions.primary = {
        size = "100%";
        content = {
          type = "luks";
          name = "elements"; # opens at /dev/mapper/elements
          askPassword = true;
          content = {
            type = "btrfs";
            extraArgs = ["-f" "-L" "elements" "-m" "dup"]; # force duplicated metadata
            subvolumes."/data" = {
              mountpoint = "/mnt/elements";
              mountOptions = ["noatime"]; # no compress no discard
            };
          };
        };
      };
    };
  };
}
