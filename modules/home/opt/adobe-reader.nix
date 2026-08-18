{
  pkgs,
  config,
  lib,
  ...
}: {
  options.modules.adobe-reader.enable = lib.mkEnableOption "Adobe Acrobat Reader DC under wine";

  config = lib.mkIf config.modules.adobe-reader.enable {
    persist.dirs = [
      ".cache/mkWindowsApp"
      ".config/adobe-acrobat-reader"
    ];

    home.packages = [pkgs.adobe-acrobat-reader];
  };
}
