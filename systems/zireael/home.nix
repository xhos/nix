{
  pkgs,
  osConfig,
  ...
}: {
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/rd/wallhaven-rdwjj7.jpg";
    sha256 = "sha256-Gv/2Ap8YS6F1S1RXlwQr71MMi+iRi9fgvZVVyZeCKvk=";
  };

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-terminal-dark.yaml";

  impermanence.enable = true;

  modules = {
    rofi.enable = true;
    secrets.enable = true;
    discord.enable = true; # TODO: re-enable — nixpkgs discord installPhase brotli-decompresses a now-gzip src
    spicetify.enable = true;
    telegram.enable = true;
    fonts.enable = true;
    rclone.enable = true;
    kdeconnect.enable = false;
    adobe-reader.enable = true;
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

  hyprland.execOnce = [
    "iio-hyprland"

    # close camera shut on boot
    "echo 1 > /sys/class/firmware-attributes/samsung-galaxybook/attributes/block_recording/current_value"
  ];
}
