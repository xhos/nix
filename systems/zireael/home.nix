{
  lib,
  pkgs,
  osConfig,
  ...
}: {
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/21/wallhaven-216d1g.png";
    sha256 = "sha256-0sSJ5dJzIAke3nW56b52N9w5Vyp5TAU1VopYg/mx4+4=";
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-terminal-dark.yaml";

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    secrets.enable = true;
    discord.enable = true;
    spicetify.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    rclone.enable = true;
  };

  wm = osConfig.wm;
  bar = "waybar";
  programs.waybar.settings.main."modules-right" = lib.mkAfter ["battery"];
  shell = "zsh";
  prompt = "starship";
  browser = "zen";
  terminal = "ghostty";

  home.packages = with pkgs; [
    iio-hyprland
    proton-vpn
  ];

  services.hypridle.enable = true;

  mainMonitor = "eDP-1";

  hyprland.execOnce = [
    "iio-hyprland" # start the rotation thingy
    "echo 1 > /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value" # close camera shut on boot
  ];
}
