{
  pkgs,
  osConfig,
  ...
}: {
  stylix.image = pkgs.fetchurl {
    url = "https://i.imgur.com/w65iDl5.jpeg";
    sha256 = "sha256-WvuZoZ6OBGa1R+zZAl6/YQAazpe8k2quJSWamTZl2Tc=";
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/eris.yaml";

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    secrets.enable = true;
    discord.enable = true; # TODO: re-enable — nixpkgs discord installPhase brotli-decompresses a now-gzip src
    spicetify.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    kdeconnect.enable = false;
  };

  wm = osConfig.wm;
  bar = "waybar";
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

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "iio-hyprland"

      # close camera shut on boot
      "echo 1 > /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value"
    ];
  };
}
