{pkgs, ...}: {
  stylix.image = pkgs.fetchurl {
    url = "http://pics.xhos.dev/u/SI12IF.png";
    sha256 = "sha256-qhRiShVq0VBiVQW5pYOWHDn/14o/PTLOlSpju8KTyRk=";
  };
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/material-darker.yaml";

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    spicetify.enable = true;
    discord.enable = true;
    secrets.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    rclone.enable = true;
  };

  wm = "hyprland";
  bar = "waybar";
  shell = "zsh";
  prompt = "starship";
  browser = "zen";

  mainMonitor = "Microstep MAG 274UPF E2 0x00000001";

  games.smokeapi = {
    appIds = [
      2161700 # Persona 3 Reload
      255710 # Cities: Skylines (native)
      949230 # Cities: Skylines II
    ];
    additionalLibraryPaths = ["/games/SteamLibrary"];
  };

  modules.wallpaperEngine = {
    enable = true;
    wallpaper = 3068206129; # lunar tear garden
    screens = ["HDMI-A-1" "HDMI-A-2"];
    crops."HDMI-A-2" = "608:1080:0:0";
  };

  hyprland.execOnce = [
    "spotify"
    "materialgram"
    "vesktop"
  ];

  home.packages = with pkgs; [
    teams-for-linux
    rustdesk
    whspr
  ];
}
