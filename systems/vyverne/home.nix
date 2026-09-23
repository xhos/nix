{pkgs, ...}: {
  # stylix.image = pkgs.fetchurl {
  #   url = "https://realmafricasafaris.com/wp-content/uploads/2020/02/The-Shoebill-Stork.jpg";
  #   sha256 = "sha256-/kIfVH281mZ8YfITslwQEwuje0aPDNsEkgQwsb6X0no=";
  # };
  #
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/og/wallhaven-ogj1gl.jpg";
    sha256 = "sha256-FXNqSqynxQPF6zNjGXymzLy+a7iaDZdR7M95wmWrisY=";
  };
  # stylix.base16Scheme = ./min-dark.yaml;
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

  wm = "hyprland";
  bar = "waybar";
  shell = "zsh";
  prompt = "starship";
  browser = "zen";

  mainMonitor = "Microstep MAG 274UPF E2 0x00000001";

  modules.smokeapi = {
    enable = true;
    appId = 2161700;
    additionalLibraryPaths = ["/games/SteamLibrary"];
  };

  hyprland.execOnce = [
    "spotify"
    "materialgram"
    "discord"
  ];

  home.packages = with pkgs; [
    jetbrains.idea
    teams-for-linux
    # whspr # broken: ctranslate2 build failure
    # android-studio-full
  ];
}
