{
  lib,
  config,
  ...
}: {
  options.bootloader.limine = {
    enable = lib.mkEnableOption "enable limine";
    dualboot = lib.mkEnableOption "show windows efi entry";
    secureboot = lib.mkEnableOption "enable secureboot";
  };

  config = {
    persist.dirs = ["/var/lib/sbctl"];
    boot = {
      plymouth.enable = true;
      loader = {
        efi.canTouchEfiVariables = true;
        limine = {
          enable = true;

          extraEntries = lib.mkIf config.bootloader.limine.dualboot ''
            /Windows
              protocol: efi
              path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
          '';

          secureBoot.enable = lib.mkIf config.bootloader.limine.secureboot true;
          style.wallpapers = lib.mkForce [];
        };
      };
    };
  };
}
