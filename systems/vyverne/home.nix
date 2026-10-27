{pkgs, ...}: {
  stylix.image = pkgs.fetchurl {
    url = "http://pics.xhos.dev/u/9prcwk.png";
    sha256 = "sha256-eeBSQ2bCTz3AHn1OBrVq8vet3yQxzM9U6FLeE02rxIM=";
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
    kdeconnect.enable = true;
  };

  games = {
    asseta.enable = true;
    beammp.enable = true;
  };

  wm = "hyprland";
  bar = "waybar";
  shell = "zsh";
  prompt = "starship";
  browser = "zen";

  mainMonitor = "Microstep MAG 274UPF E2 0x00000001";

  modules.smokeapi = {
    enable = true;
    appIds = [
      2161700 # Persona 3 Reload
      255710 # Cities: Skylines (native)
      949230 # Cities: Skylines II
    ];
    additionalLibraryPaths = ["/games/SteamLibrary"];
  };

  hyprland.execOnce = [
    "spotify"
    "materialgram"
    "vesktop"
  ];

  home.packages = with pkgs; [
    r2modman
    teams-for-linux
    rustdesk
    whspr
  ];
}
