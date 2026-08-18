{
  pkgs,
  config,
  lib,
  ...
}: {
  options.games.enable = lib.mkEnableOption "gaming support (Steam, Prismlauncher)";

  config = lib.mkIf config.games.enable {
    environment.systemPackages = with pkgs; [
      prismlauncher
      wineWow64Packages.stable
      winetricks
      lutris
    ];

    programs.steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin proton-ge-9-20];
    };

    services.zerotierone = {
      enable = true;
      joinNetworks = ["abfd31bd47fb27ef"];
    };
  };
}
