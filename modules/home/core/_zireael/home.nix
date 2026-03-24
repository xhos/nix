{
  pkgs,
  osConfig,
  ...
}: {
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/vp/wallhaven-vpz5w5.jpg";
    sha256 = "sha256-38xqvUxDURO5W85IMAVDVHf5cpJiUKmQAoDEpKdTn8E=";
  };

  stylix.base16Scheme = ./min-darker.yaml;

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    secrets.enable = true;
    discord.enable = true;
    spicetify.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    kdeconnect.enable = true;
  };

  wm = osConfig.wm;
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
