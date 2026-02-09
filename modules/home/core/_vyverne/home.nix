{pkgs, ...}: {
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/ex/wallhaven-exdl2k.jpg";
    sha256 = "sha256-pg1GKu/rwOwWG8Gqc+TWLsvoG791DR+Y9/RGglPxtYE=";
  };

  stylix.base16Scheme = ./min-dark.yaml;

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    spicetify.enable = true;
    firefox.enable = true;
    discord.enable = true;
    secrets.enable = true;
    telegram.enable = true;
    whisper.enable = true;
    fonts.enable = true;
    rclone.enable = true;
    kdeconnect.enable = true;
  };

  de = "hyprland";
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

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "[workspace special silent] spotify"
      "[workspace 10 silent] materialgram"
      "[workspace 10 silent] discord"
    ];

    windowrule = [
      "workspace special silent, match:initial_class ^(spotify)$"
      "workspace 10 silent, match:initial_title ^(materialgram)$"
      "workspace 10 silent, match:initial_class ^(discord)$"
    ];
  };

  home.packages = with pkgs; [jetbrains.idea teams-for-linux];
}
