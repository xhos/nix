{
  pkgs,
  lib,
  config,
  ...
}: {
  options.modules.fonts.enable = lib.mkEnableOption "custom font collection";

  config = lib.mkIf config.modules.fonts.enable {
    fonts.fontconfig.enable = true;
    home.file.".local/share/fonts".source = ./font-files;
    home.packages = with pkgs; [
      # icon fonts
      material-design-icons

      # normal fonts
      font-awesome
      dosis
      rubik
      lexend
      lexend
      noto-fonts
      noto-fonts-cjk-sans
      (google-fonts.override {fonts = ["Dela Gothic One" "Shippori Mincho" "Zen Old Mincho" "M PLUS Rounded 1c" "DotGothic16" "Klee One"];})
      noto-fonts-color-emoji
      poppins

      roboto
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.fantasque-sans-mono
      nerd-fonts.zed-mono
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
    ];
  };
}
