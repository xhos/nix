{pkgs, ...}: {
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/7j/wallhaven-7j9wle.png";
    sha256 = "sha256-oBe7QloMCdxZijzos/VRzZ5kuR3mHh7L2LIKKdtUysI=";
  };

  stylix.base16Scheme = ./min-dark.yaml;

  impermanence.enable = false;

  modules = {
    rofi.enable = true;
    secrets.enable = true;
    discord.enable = true;
    spicetify.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    kdeconnect.enable = true;
  };

  de = "hyprland";
  bar = "waybar";
  shell = "zsh";
  prompt = "starship";
  browser = "zen";
  terminal = "ghostty";

  home.packages = with pkgs; [
    iio-hyprland
  ];

  services.hypridle.enable = true;

  mainMonitor = "eDP-1";

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "iio-hyprland"

      # close camera shut on boot
      "echo 1 > /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value"
    ];
  };
}
