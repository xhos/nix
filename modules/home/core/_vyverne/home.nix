{pkgs, ...}: {
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/5g/wallhaven-5g1ep5.jpg";
    sha256 = "sha256-0r+WD32FdoXAwqg+5t4F9JLmIAtA0DO9t3hnafjRnaI=";
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
  };

  de = "hyprland";
  bar = "waybar";
  shell = "zsh";
  prompt = "starship";
  browser = "zen";
  terminal = "ghostty";

  mainMonitor = "Microstep MAG 274UPF E2 0x00000001";

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "[workspace special silent] spotify"
      "[workspace 10 silent] materialgram"
      "[workspace 10 silent] discord"
    ];

    windowrulev2 = [
      "workspace special silent, initialClass: spotify"
      "workspace 10 silent, initialTitle: materialgram"
      "workspace 10 silent, initialClass: discord"
    ];
  };

  home.packages = with pkgs; [jetbrains.idea teams-for-linux];
}
